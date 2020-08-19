package Serge::Sync::Plugin::TranslationService::Smartcat;
use parent Serge::Sync::Plugin::Base::TranslationService,
  Serge::Interface::SysCmdRunner;

use strict;
use warnings;

use File::Basename;
use File::Spec::Functions qw(rel2abs);
use Serge::Util qw(subst_macros);

our $VERSION = "0.0.6";

sub name {
    return
'Smartcat translation server (http://smartcat.io/) .po synchronization plugin';
}

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->merge_schema(
        {
            base_url   => 'STRING',
            project_id => 'STRING',
            token_id   => 'STRING',
            token      => 'STRING',
            project_translation_files_path => 'STRING',
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
    $self->{data}->{project_translation_files_path} = subst_macros( $self->{data}->{project_translation_files_path} );

    unless ( $self->{data}->{project_translation_files_path} ) {
        my %job_ts_file_paths;
        $job_ts_file_paths{ $_->{ts_file_path} }++
          for @{ $self->{parent}{config}{data}{jobs} };
        my @job_ts_file_paths = keys %job_ts_file_paths;
        die sprintf( "Set 'project_translation_files_path' parameter, more than one 'ts_file_path' found in the config file: %s",
              join( ', ', map { "'$_'" } @job_ts_file_paths ) )
          if @job_ts_file_paths > 1;
        my $ts_file_path = shift @job_ts_file_paths;

        die sprintf(
    "'ts_file_path' which is set to '%s', doesn't match '%%LANG%%' pattern.",
              $ts_file_path )
          unless $ts_file_path =~
          m/(%LOCALE%|%LANG%).*$self->{data}->{filetype}/;

        $self->{data}->{project_translation_files_path} =
          dirname( dirname($ts_file_path) );

        die sprintf(
    "'ts_file_path' parent directory, which is set to '%s', does not point to a valid directory. Run 'localize' to generate translation files.",
            $self->{data}->{project_translation_files_path} )
          unless -d $self->{data}->{project_translation_files_path};
    } else {
        die sprintf(
    "'project_translation_files_path', which is set to '%s', does not point to a valid directory. Run 'localize' to generate translation files.",
            $self->{data}->{project_translation_files_path} )
          unless -d $self->{data}->{project_translation_files_path};
    }


    $self->{data}->{base_url}   = subst_macros( $self->{data}->{base_url} );
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

    $command .= " --base-url=" . $self->{data}->{base_url}
      if defined $self->{data}->{base_url};
    $command .= " --token-id=" . $self->{data}->{token_id}
      if defined $self->{data}->{token_id};
    $command .= " --token=" . $self->{data}->{token}
      if defined $self->{data}->{token};
    $command .=
      " --project-workdir=" . $self->{data}->{project_translation_files_path};
    $command .= " --log=" . $self->{data}->{log_file}
      if defined $self->{data}->{log_file};

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
    $options .= ' --skip-missing';

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
    $options .= ' --delete-not-existing';

    return $self->run_smartcat_cli( 'push' . $options, $langs );
}

1;

__END__

=encoding utf-8

=head1 NAME

Serge::Sync::Plugin::TranslationService::Smartcat - L<Smartcat translation server|http://smartcat.ai> .po synchronization plugin.

=head1 INSTALLATION

  > cpanm Serge::Sync::Plugin::TranslationService::Smartcat

=head1 DESCRIPTION

Serge::Sync::Plugin::TranslationService::Smartcat is a syncronization plugin which allows to build an integration between L<Serge|https://serge.io> (Free, Open Source Solution for Continous Localization) and L<Smartcat|http://smartcat.ai/>.

For more details visit <GitHub|https://github.com/smartcatai/smartcat-serge-sync-plugin>.

=head1 AUTHOR

Taras Semenenko <taras.semenenko@gmail.com>

=cut

