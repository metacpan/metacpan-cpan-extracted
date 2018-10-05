package Serge::Sync::Plugin::TranslationService::Smartcat;
use parent Serge::Sync::Plugin::Base::TranslationService,
  Serge::Interface::SysCmdRunner;

use strict;
use warnings;

use File::Basename;
use File::Spec::Functions qw(rel2abs);
use Serge::Util qw(subst_macros);

our $VERSION = "0.0.1";

sub name {
    return
'Smartcat translation server (http://smartcat.io/) .po synchronization plugin';
}

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->merge_schema(
        {
            project_id => 'STRING',
            token_id   => 'STRING',
            token      => 'STRING',
            push       => {
                disassemble_algorithm_name => 'STRING',
            },
            pull => {
                complete_projects  => 'BOOLEAN',
                complete_documents => 'BOOLEAN',
            },
            filetype           => 'STRING',
            language_file_tree => 'BOOLEAN',

            log_file => 'STRING',
            debug    => 'BOOLEAN',
        }
    );
}

sub validate_data {
    my ($self) = @_;

    $self->SUPER::validate_data;

    $self->{data}->{filetype} = subst_macros( $self->{data}->{filetype} );

    my %job_ts_file_paths;
    $job_ts_file_paths{ $_->{ts_file_path} }++
      for @{ $self->{parent}{config}{data}{jobs} };
    my @job_ts_file_paths = keys %job_ts_file_paths;
    die sprintf( "More than one 'ts_file_path' found in the config file: %s" %
          join( ', ', map { "'$_'" } @job_ts_file_paths ) )
      if @job_ts_file_paths > 1;
    my $ts_file_path = shift @job_ts_file_paths;
    die sprintf(
"'ts_file_path' which is set to '%s', doesn't match '%LOCALE%/%FILE%' pattern."
          % $ts_file_path )
      unless $ts_file_path =~
      m/(%LOCALE%|%LANG%)\/%FILE%$self->{data}->{filetype}/;

    $self->{data}->{project_translation_files_path} =
      dirname( dirname($ts_file_path) );

    die sprintf(
"'ts_file_path' parent directory, which is set to '%s', does not point to a valid directory. Run 'localize' to generate translation files.",
        $self->{data}->{project_translation_files_path} )
      unless -d $self->{data}->{project_translation_files_path};

    $self->{data}->{project_id} = subst_macros( $self->{data}->{project_id} );
    $self->{data}->{token_id}   = subst_macros( $self->{data}->{token_id} );
    $self->{data}->{token}      = subst_macros( $self->{data}->{token} );

    if ( exists $self->{data}->{push} ) {
        $self->{data}->{push}->{disassemble_algorithm_name} =
          subst_macros( $self->{data}->{push}->{disassemble_algorithm_name} );
    }
    if ( exists $self->{data}->{pull} ) {
        $self->{data}->{pull_complete_documents} =
          subst_macros( $self->{data}->{pull}->{complete_documents} );
        $self->{data}->{pull}->{complete_projects} =
          subst_macros( $self->{data}->{pull}->{complete_projects} );
    }
    $self->{data}->{log_file} = subst_macros( $self->{data}->{log_file} );
    $self->{data}->{language_file_tree} =
      subst_macros( $self->{data}->{language_file_tree} );

    $self->{data}->{debug} = subst_macros( $self->{data}->{debug} );

    die "'project_id' not defined" unless defined $self->{data}->{project_id};

    if ( $self->{data}->{log_file} ) {
        my $log_dir = rel2abs( dirname( $self->{data}->{log_file} ) );
        die
"'log_file' parent directory which is set to '$log_dir', does not point to a valid directory.\n"
          unless -d $log_dir;
    }

    $self->{data}->{push} = {} unless defined $self->{data}->{push};
    $self->{data}->{push}->{disassemble_algorithm_name} = 'Serge.io PO'
      unless defined $self->{data}->{push}->{disassemble_algorithm_name};
    $self->{data}->{filetype} = '.po' unless defined $self->{data}->{filetype};
    $self->{data}->{pull}     = {}    unless defined $self->{data}->{pull};
    $self->{data}->{pull}->{complete_projects} = 0
      unless $self->{data}->{pull}->{complete_projects};
    $self->{data}->{pull}->{complete_documents} = 0
      unless $self->{data}->{pull}->{complete_documents};
}

sub run_smartcat_cli {
    my ( $self, $action, $langs ) = @_;

    my $command = $action . ' --project-id=' . $self->{data}->{project_id};

    $command .= " --token-id=" . $self->{data}->{token_id}
      if defined $self->{data}->{token_id};
    $command .= " --token=" . $self->{data}->{token}
      if defined $self->{data}->{token};
    $command .=
      " --project-workdir=" . $self->{data}->{project_translation_files_path};
    $command .= " --log=" . $self->{data}->{log_file};

    if ( $self->{data}->{language_file_tree} ) {
        $command .= " --language-file-tree";
    }

    $command .= " --debug" if $self->{data}->{debug};

    $command = 'smartcat-cli ' . $command;
    my $result = $self->run_cmd($command);

    return $result;
}

sub run_cmd {
    my ( $self, $command, $ignore_codes ) = @_;

    my $line = $command;
    $line =~ s/(\-\-token=\").+?(\")/$1******$2/;
    $line =~ s/(\-\-token=).+?(\s)/$1******$2/ unless $1;
    print "Running '$line'...\n";

    my $result = "";
    print "\n--------------------\n";
    system($command);    # output will be echoed but not captured
    print "\n--------------------\n";

    my $error_code = unpack 'c', pack 'C', $? >> 8;    # error code

    if (
           ( $error_code > 0 )
        && $ignore_codes
        && ( ref( \$ignore_codes ) eq 'SCALAR'
            || ( grep( $_ eq $error_code, @$ignore_codes ) > 0 ) )
      )
    {
        print "Exit code: $error_code (ignored)\n" if $self->{debug};
        $error_code = 0;
    }

    die $result . "\nExit code: $error_code; last error: $!\n"
      if $error_code != 0;

    return $result;
}

sub pull_ts {
    my ( $self, $langs ) = @_;

    my $options       = '';
    my $pull_settings = $self->{data}->{pull};
    $options .= ' --complete-documents' if $pull_settings->{complete_documents};
    $options .= ' --complete-projects'  if $pull_settings->{complete_projects};

    return $self->run_smartcat_cli( 'pull' . $options, $langs );
}

sub push_ts {
    my ( $self, $langs ) = @_;

    my $options       = '';
    my $push_settings = $self->{data}->{push};
    $options .=
      ' --disassemble-algorithm-name="'
      . $push_settings->{disassemble_algorithm_name} . '"'
      if $push_settings->{disassemble_algorithm_name};

    return $self->run_smartcat_cli( 'push' . $options, $langs );
}

1;

__END__

=encoding utf-8

=head1 NAME

Serge::Sync::Plugin::TranslationService::Smartcat - L<Smartcat translation server|http://smartcat.io/> .po synchronization plugin.

=head1 INSTALLATION

  > cpanm Serge::Sync::Plugin::TranslationService::Smartcat

or

  > cpanm https://github.com/ta2-1/smartcat-serge-sync-plugin/tarball/master


=head1 DESCRIPTION

Serge::Sync::Plugin::TranslationService::Smartcat is a syncronization plugin which allows to build an integration between L<Serge|https://serge.io/> (Free, Open Source Solution for Continous Localization) and L<Smartcat|http://smartcat.io/>.

=head1 DESCRIPTION OF CONFIG PARAMETERS

    sync
    {
        ts
        {
            plugin                      Smartcat

            data
            {
                /*
                    (STRING) Unique Smartcat project id
                */
                project_id              12345678-1234-1234-1234-123456789012

                /*
                    (STRING) [OPTIONAL] Account Id
                    from https://smartcat.ai/ApiAccess/Credentials

                    Default is read from `smartcat-cli` application config
                */
                token_id                12345678-1234-1234-1234-123456789012

                /*
                    (STRING) [OPTIONAL] API key
                    from https://smartcat.ai/ApiAccess/Credentials

                    Default is read from `smartcat-cli` application config
                */
                token                   1_1234567890123456789012345

                # push-ts parameters
                push {
                    /*
                        (STRING) [OPTIONAL]
                        Default is Serge.io PO
                    */
                    disassemble_algorithm_name       Serge.io PO
                }

                # pull-ts parameters
                pull {
                    /*
                        (BOOLEAN) [OPTIONAL] If 'complete_projects'
                        is set to a true value, the whole project will not
                        be pulled from Smartcat if its status doesn't
                        equal 'complete'
                        Default is NO
                    */
                    complete_projects                NO

                    /*
                        (BOOLEAN) [OPTIONAL] If 'complete_documents'
                        is set to a true value, the document will not be
                        pulled from Smartcat if its status doesn't
                        equal 'complete'
                        Default is NO
                    */
                    complete_documents               NO
                }

                /*
                    (STRING) [OPTIONAL]
                    Default is read from `smartcat-cli` application config
                */
                log_file                             /path/to/log/file

                /*
                    (STRING) [OPTIONAL]
                    Default is ".po"
                */
                filetype                             .po

                /*
                    (BOOLEAN) [OPTIONAL] If 'language_file_tree' is set
                    to a true value (EXPERIMENTAL MODE), same '.po' files from
                    direfferent language directories will be added to Smartcat as
                    leafs of the only tree document
                    Default is NO
                */
                language_file_tree                   NO

                /*
                    (BOOLEAN) [OPTIONAL]
                    Default is NO
                */
                debug                                YES
            }
        }

        # other sync parameters
        # ...
    }

=head1 MINIMAL CONFIG SAMPLE

    sync
    {
        ts
        {
            plugin                      Smartcat

            data
            {
                # token and token_id should be set via 'smartcat-cli' config file

                project_id              12345678-1234-1234-1234-123456789012
            }
        }
    }

=head1 AUTHOR

Taras Semenenko <taras.semenenko@gmail.com>

=cut

