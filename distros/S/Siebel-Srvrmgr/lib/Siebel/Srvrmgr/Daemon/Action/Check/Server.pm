package Siebel::Srvrmgr::Daemon::Action::Check::Server;

use warnings;
use strict;
use Moose::Role 2.0401;
use Siebel::Srvrmgr::Types;
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::Check::Server - role for classes that hold Siebel server components information

=head1 DESCRIPTION

This package is a role, not a subclass of L<Siebel::Srvrmgr::Daemon::Action>. It is intended to be used by classes 
that provides information about components available in a Siebel server and which is their expected status.

=head1 ATTRIBUTES

=head2 name

A string representing the name of the Siebel Server.

=cut

has name => (
    isa      => 'NotNullStr',
    is       => 'rw',
    required => 1,
    reader   => 'get_name'
);

=pod

=head2 components

An array reference with instances of classes that have the L<Siebel::Srvrmgr::Daemon::Action::Check::Component> 
role applied.

=cut

# :TODO      :24/07/2013 12:41:06:: this has to be changed to a HashRef to enable searching objects by name
has components => (
    isa      => 'ArrayRef[CheckCompsComp]',
    is       => 'rw',
    required => 1,
    reader   => 'get_components'
);

=pod

=head1 METHODS

Each attribute has it's respective getter named as C<get_><attribute name>.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon::Action::Check::Component>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

1;
