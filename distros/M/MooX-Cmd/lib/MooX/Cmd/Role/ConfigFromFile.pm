package MooX::Cmd::Role::ConfigFromFile;

use strict;
use warnings;

our $VERSION = "0.015";

use Moo::Role;

=head1 NAME

MooX::Cmd::Role::ConfigFromFile - MooX::ConfigFromFile support role for MooX::Cmd

=cut

requires "config_prefixes";

around _build_config_prefixes => sub {
    my $next     = shift;
    my $class    = shift;
    my $params   = shift;
    my $cfg_pfxs = $class->$next( $params, @_ );

    ref $params->{command_chain} eq "ARRAY"
      and push @{$cfg_pfxs},
      grep { defined $_ } map { $_->command_name } grep { $_->can("command_name") } @{ $params->{command_chain} };

    return $cfg_pfxs;
};

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
