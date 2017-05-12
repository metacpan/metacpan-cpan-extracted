package Padre::Plugin::Shell::Command;
use base 'Padre::Plugin::Shell::Base';

use 5.008;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Current  ();
use Padre::Wx       ();
use File::Which;

our $VERSION = '0.27';

my %actions = (
    append  => 1,
    replace => 2,
    new     => 3,
);

sub plugin_menu {
    my ($self) = @_;
    my @menu = ();
    push @menu, Wx::gettext("Run Command, Append\tAlt+Shift+R") => sub { $self->run_command( $actions{append} ) };
    push @menu, Wx::gettext("Run Command, Replace")             => sub { $self->run_command( $actions{replace} ) };
    push @menu, Wx::gettext("Run Command, New")                 => sub { $self->run_command( $actions{new} ) };
    return @menu;
}

sub get_cmd {
    my ( $self, $editor ) = @_;
    my %cmd;

    if ( $editor->GetSelectedText() ) {
        $cmd{cmd} = $editor->GetSelectedText();
        my $start_pos  = $editor->GetSelectionStart();
        my $start_line = $editor->LineFromPosition($start_pos);
        my $end_pos    = $editor->GetSelectionEnd();
        my $end_line   = $editor->LineFromPosition($end_pos);
        $cmd{line_count} = $end_line - $start_line;
    }
    else {

        # the command is the current line
        my $cmd_line  = $editor->LineFromPosition( $editor->GetCurrentPos() );
        my $start_pos = $editor->PositionFromLine($cmd_line);
        my $end_pos   = $editor->GetLineEndPosition($cmd_line);
        $editor->SetSelection( $start_pos, $end_pos );
        $cmd{cmd}        = $editor->GetSelectedText();
        $cmd{line_count} = 1;
    }
    $cmd{has_shebang} = ( $cmd{cmd} =~ m/^\s*#!/ ) ? 1 : 0;

    # is it a command or should/can it be wrapped in a cat block and run through sh?
    unless ( $cmd{has_shebang} ) {
        my ($test) = $cmd{cmd} =~ m/^\s*([^\s]+)/;
        $test = ( split /[\/\\]/, $test )[-1];
        unless ( which($test) ) {
            if ( which('cat') && which('sh') ) {
                $cmd{cmd}         = "#!/bin/sh\ncat <<EIEIOT\n" . $cmd{cmd} . "\nEIEIOT\n";
                $cmd{has_shebang} = 1;
            }
            else {
                $cmd{cmd} = '';
            }
        }
    }
    return %cmd;
}

sub run_command {
    my ( $self, $action ) = @_;

    my $editor = Padre::Current->editor or return;
    $editor->Freeze;

    $self->update_environment_vars($editor);

    my %cmd = $self->get_cmd($editor);
    my @cmd_out;

    if ( $cmd{has_shebang} || $cmd{line_count} != 1 ) {
        my $filename = $self->get_temp_file();
        my $fh;
        if ( open $fh, '>', $filename ) {
            print $fh $cmd{cmd};
            close $fh;
            `chmod u+x $filename`;

            # Use shebang if there is one, otherwise not.
            @cmd_out
                = ( $cmd{has_shebang} )
                ? `./$filename 2>&1`
                : `sh $filename 2>&1`;

            # In case of errors, we don't want the temp filename
            # showing up in the output as it is pretty ugly and
            # doesn't add anything to the conversation.
            if ($?) {
                $_ =~ s/^[.\/]*$filename/ERR/ for @cmd_out;
            }

            $self->delete_temp_file($filename);
        }
    }
    else {

        # It's a one-liner
        @cmd_out = `$cmd{cmd} 2>&1`;
    }

    if (@cmd_out) {
        my $filename = $self->get_temp_file();
        my $fh;
        if ( open $fh, '>', $filename ) {
            print $fh @cmd_out;
            close $fh;

            if ( $action == $actions{replace} ) {
                $self->replace_selection_from_file($filename);
            }
            elsif ( $action == $actions{append} ) {
                $self->append_selection_from_file($filename);
            }
            elsif ( $action == $actions{new} ) {
                $self->new_document_from_file( $filename, 'text/plain' );
            }
        }
        $self->delete_temp_file($filename);
    }
    $editor->Thaw;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Shell::Command - The Shell Command plug-in functions

=head1 DESCRIPTION

This plug-in takes shell commands from the active document and inserts the 
output of the command into the document.

If text is selected then the plug-in will attempt to execute the selected text.
If no text is selected the the plug-in will attempt to execute the current line 
as a command.

"Commands" can either be valid shell commands, entire scripts (with shebang), or
environment variables to be evaluated.

There are three associated menu items:

=over

=item "Run Command, Insert" inserts the command output after the command while 

=item "Run Command, Replace" replaces the command with the command output.

=item "Run Command, New" creates a new document with the command output.

=back

=head1 ENVIRONMENT VARIABLES

To provide additional information for the filters, various
environment variables are set prior to running the filter.  
These environment variables are covered in the 
L<Padre::Plugin::Shell::Base> documentation.

=head1 EXAMPLES

=head4 Example 1

Typing `$USER` on an otherwise blank line and invoking 'Run Command'
without selecting anything would insert your user-name on the next line down.

    $USER
    gsiems

=head4 Example 2

Combinations of Environment variables and commands are also possible:

    $USER was last seen on `date`
    gsiems was last seen on Fri Oct  9 16:12:11 CDT 2009

=head4 Example 3

By typing, on an otherwise blank line, `The date is:` then selecting the word 
`date` and invoking 'Run Command' results in the date being inserted on the 
next line down.

    The date is:
    Fri Oct  9 16:12:11 CDT 2009

=head4 Example 4 (Mult-line scripts)

Typing a multi-line script, selecting the entire script and invoking 
'Run Command' will run the entire selection as a shell script:

So:

    for I in 1 2 3 ;
        do
        echo " and a $I"
    done
    
Inserts:

     and a 1
     and a 2
     and a 3

after the script block.

=head4 Example 5 (The whole shebang)

Shebangs are supported so the scripts aren't limited to shell commands/scripts.

For example, typing (and selecting) the following

    #!/usr/bin/env perl
    print " and a $_\n" for (qw(one two three));
    
and invoking 'Run Command' inserts:

     and a one
     and a two
     and a three

after the script block.

=head4 Example 6 (PE_ variables)

Running the following:

    #!/bin/sh
    set | grep "^PE_"

Inserts something like:

    PE_BASENAME=padre_test.pl
    PE_CONFIG_DIR=/home/gsiems/.padre
    PE_DEF_PROJ_DIR=/home/gsiems/projects
    PE_DIRECTORY=/home/gsiems
    PE_FILEPATH=/home/gsiems/padre_test.pl
    PE_INDENT_TAB=NO
    PE_INDENT_TAB_WIDTH=4
    PE_INDENT_WIDTH=4
    PE_MIMETYPE=application/x-perl

So, for instance, a user created script `mkheader` could use PE_BASENAME 
and PE_MIMETYPE to create an appropriate header for different file types.

=head1 METHODS

=head2 get_cmd ($editor)

Determines and returns the command is that is to be run.

=head2 plugin_menu

Returns a menu items for the plugin.

=head2 run_command ($action)

Runs the command and performs the appropriate $action with the result.

=head1 LIMITATIONS

This plug-in will not work on operating systems that do not have an appropriate 
shell environment (such as MS Windows).

=head1 AUTHOR

Gregory Siems E<lt>gsiems@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gregory Siems

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

