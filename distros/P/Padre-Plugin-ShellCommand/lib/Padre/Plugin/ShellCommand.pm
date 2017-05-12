package Padre::Plugin::ShellCommand;
use base 'Padre::Plugin';

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();
use Padre::Wx     ();
use Padre::Plugin::Shell::Command;

our $VERSION = '0.27';

my $command_plugin;

#####################################################################
# Padre::Plugin Methods

sub plugin_name {
    'ShellCommand';
}

sub padre_interfaces {
    'Padre::Plugin' => 0.43;
}

sub menu_plugins_simple {
    my ($self) = @_;
    $command_plugin = Padre::Plugin::Shell::Command->new();
    my @command_menu = $command_plugin->plugin_menu();
    'ShellCommand' => [@command_menu];
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::ShellCommand - A Shell Command plug-in

=head1 DESCRIPTION

This plug-in takes shell commands from the active document and inserts the 
output of the command into the document.

If text is selected then the plug-in will attempt to execute the selected text.
If no text is selected the the plug-in will attempt to execute the current line 
as a command.

"Commands" can either be valid shell commands, entire scripts (with shebang), or
environment variables to be evaluated.

See L<Padre::Plugin::Shell::Command> for details.

=head1 ENVIRONMENT VARIABLES

To provide additional information for the plugin, various 
environment variables are set prior to performing the plugin 
action. These environment variables are covered in the 
L<Padre::Plugin::Shell::Base> documentation.

=head1 AUTHOR

Gregory Siems E<lt>gsiems@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gregory Siems

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
