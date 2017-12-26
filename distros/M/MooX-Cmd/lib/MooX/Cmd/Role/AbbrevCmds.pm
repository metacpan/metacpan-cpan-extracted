package MooX::Cmd::Role::AbbrevCmds;

use strict;
use warnings;

our $VERSION = "0.017";

use Text::Abbrev;

use Moo::Role;

=head1 NAME

MooX::Cmd::Role::AbbrevCmds - Text::Abbrev support role for MooX::Cmd

=cut

requires "command_commands";

around _build_command_commands => sub {
    my $next     = shift;
    my $class    = shift;
    my $params   = shift;
    my $cmd_cmds = $class->$next($params, @_);

    my %abbrevs = abbrev keys %$cmd_cmds;
    my %cmd_cmds = map { $_ => $cmd_cmds->{$abbrevs{$_}} } keys %abbrevs;

    return \%cmd_cmds;
};

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;

