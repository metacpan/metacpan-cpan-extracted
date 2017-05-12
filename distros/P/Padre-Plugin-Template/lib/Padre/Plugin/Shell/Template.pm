package Padre::Plugin::Shell::Template;
use base 'Padre::Plugin::Shell::Base';

use 5.008;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Current  ();
use Padre::Util     ();
use Padre::Wx       ();
use File::Which;

our $VERSION = '0.1';

########################################################################
#
sub plugin_menu {
    my ($self) = @_;
    my @menu   = ();
    my %config = $self->get_config();
    my @accel_keys = ( 0 .. 9, 'A' .. 'Z' );

    foreach my $template ( sort keys %config ) {
        my $accel = '';
        if (@accel_keys) {
            my $a = shift @accel_keys;
            $accel = '&' . $a . ' - ';
        }
        push @menu, "$accel$template" => sub { $self->new_from_template($template) };
    }
    push @menu, '---' => undef;
    push @menu, Wx::gettext("&Configure Templates") => sub { $self->edit_config_file() },;

    return @menu;
}

sub example_config {
    my ($self) = @_;

    my $config = "---\n";

    # Start by loading the templates from Padre itself as:
    #   1. they probably exist, and
    #   2. they make good working examples
    my %templates = (
        'pl' => Wx::gettext('Perl 5 Script'),
        'pm' => Wx::gettext('Perl 5 Module'),
        'p6' => Wx::gettext('Perl 6 Script'),
        't'  => Wx::gettext('Perl 5 Test'),
    );
    
    # NOTE: if we have sh then we want to copy the file 
    # (and thus short circuit sh), otherwise leave the command blank.
    my $cmd = (which ('sh')) ? 'cp [% IN %] [% OUT %]' : '';
    
    foreach my $extension ( sort keys %templates ) {
        my $template_pathname = File::Spec->catfile( 
            Padre::Util::sharedir('templates'), "template.$extension" 
            );
        next unless ( -f $template_pathname );
        my $template_name = $templates{$extension};
        $config .= <<"EOT";
$template_name:
  command: '$cmd'
  description: Create a new $template_name
  mimetype: ''
  source_file: $template_pathname
EOT
    }

    # Add something that is not perl/Padre
    # TODO: example for systems without sh
    # TODO: create the example template
    if ( which('sh') ) {
        my $template_pathname = File::Spec->catfile( 
            Padre::Constant::CONFIG_DIR, 'templates', "template.sh" 
            );

        $config .= <<"EOT";
Shell Script:
  command: ''
  description: Create a new Shell Script
  mimetype: 'application/x-shellscript'
  source_file: $template_pathname

EOT
    }
    return $config;
}

sub new_from_template {
    my ( $self, $template ) = @_;
    my %config = $self->get_config();
    if ( exists $config{$template} ) {
        my $command  = $config{$template}{command}  || '';
        my $mimetype = $config{$template}{mimetype} || '';
        my $template_file = $config{$template}{source_file};

        ################################################################
        # Setup the environment
        $self->update_environment_vars();

        my $in_filename  = $self->get_temp_file();
        my $out_filename = $self->get_temp_file();

        # 1. If there is a command then
        #  - get a temporary output file
        #  - call the command with the template and temporary output file
        #  - create new from output file
        #  - rm out file
        if ($command) {
            $command =~ s/\[\% IN \%\]/$template_file/;
            $command =~ s/\[\% OUT \%\]/$out_filename/;
            my $rc = system($command);
            if ( $rc == -1 ) {
                $self->notify_of_error( 
                    Wx::gettext("Failed to run template command.\n") . $! 
                    );
                return;
            }
            $self->new_document_from_file( $out_filename, $mimetype );
        }

        # 2. else If we have a shell & cat then:
        #  - get a temporary file
        #  - wrap things in cat and redirect the output to the temporary file
        #  - create new from temporary out file
        #  - rm out file
        elsif ( which('cat') && which('sh') ) {
            my $template_text = $self->slurp_file($template_file);
            my $IN;
            if ( open $IN, '>', $in_filename ) {
                print $IN <<"EOT";
cat <<PADRE_EOT > $out_filename
$template_text
PADRE_EOT
EOT
                close $IN;

                my $rc = system("sh $in_filename");
                if ( $rc == -1 ) {
                    $self->notify_of_error( 
                        Wx::gettext("Failed to run template command.\n") . $! 
                        );
                    return;
                }
                $self->new_document_from_file( $out_filename, $mimetype );
            }
        }

        # 3. otherwise just create from the static template
        else {
            $self->new_document_from_file( $template_file, $mimetype );
        }

        $self->delete_temp_file($out_filename);
        $self->delete_temp_file($in_filename);
    }
}
1;

=pod

=head1 NAME

Padre::Plugin::Shell::Template - Create new documents from templates.

=head1 DESCRIPTION

Create new documents from a list of user defined templates. Optionally, 
the template may be processed with an external command prior to creating 
the new document.

=head1 CONFIGURATION

Template definitions are kept in a YAML formatted configuration file
in the user's Padre configuration directory (C<~/.padre>).

Each template is labeled with the name that is to be displayed in the 
template menu. In addition to the name there are four attributes for 
each template definition:

=over

=item B<command> (optional) -  

The command to process the template through prior to creating a new document.

=item B<description> (optional) - 

A description of the template. This is not [currently] used by the plugin 
and is intended for the benefit of the individual maintaining the template 
configuration.

=item B<mimetype> (optional) - 

The mimetype of the created document. If no mimetype is specified the 
Padre will be attempt to guess the mimetype.

=item B<source_file (required)> - 

The full path and name of the template file.

=back

=head1 ENVIRONMENT VARIABLES

To provide additional information for the templates, various
environment variables are set prior to processing the template.  
These environment variables are covered in the 
L<Padre::Plugin::Shell::Base> documentation.

=head1 METHODS

=head3 plugin_menu

Generates and returns a menu of the defined templates.

=head3 example_config

Returns an example configuration. This is the initial configuration 
that gets created the first time that this plugin is used.

=head3 new_from_template ($template_name)

Searches the template configuration for a template definition that 
matches the supplied $template_name. If a matching template is found 
then one of three actions is performed.

=over

=item B<Use command> - 

If a command is supplied as part of the template configuration then 
the template is processed through that command and the output is used 
to create the new document.

There are two rather important placeholders in the command string 
C<[% IN %]> and C<[% OUT %]> for the input and output filenames used 
in running the command. When the command is run, the C<[% IN %]> 
placeholder is replaced with the template filename and the C<[% OUT %]>
placeholder is replaced by the name temporary file that the command
is to write to.

=item B<Use the shell> - 

If no command is supplied and the system has both C<cat> and C<sh> 
available then the template is wrapped in a C<cat> block and executed 
using C<sh>.

By using this approach it is possible to include environment variables 
and other commands within the template. For example, the combination of 
C<$USER> and C<`date +%F`> could be used to insert the current user and 
date into the documentation section of a new script.

As a result of this approach, any dollar signs (C<$>) that are to be 
preserved in the template need to be escaped as do any back ticks (C<`>). 
To avoid this behavior on systems with both C<cat> and C<sh>, specify 
C<cp [% IN %] [% OUT %]> as the command to execute as this will simply 
copy the template to a temporary file before creating the new document.

=item B<Use nothing> - 

If no command is specified and the system does not have C<cat> and C<sh> 
then the new document is created from the template as is.

=back

=head1 ISSUES

When adding entries to the configuration file it appears to be necessary 
to have an empty line at the end of the file in order for the configuration 
to properly load. No properly loaded configuration results in no menu 
for the plug-in.

=head1 AUTHOR

Gregory Siems E<lt>gsiems@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gregory Siems

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
