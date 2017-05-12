package Siebel::Srvrmgr::Daemon::Action::Check::Component;

use warnings;
use strict;
use Moose::Role 2.0401;
use Siebel::Srvrmgr::Types;
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action::Check::Component - role for classes that hold Siebel server components information

=head1 DESCRIPTION

This Moose Role is intended to be used by classes that provides information about which components are available in 
a Siebel server and which is their expected status.

=head1 ATTRIBUTES

=head2 alias

A string representing the alias of the component.

=cut

has alias => (
    isa      => 'NotNullStr',
    is       => 'ro',
    reader   => 'get_alias',
    required => 1
);

=pod

=head2 description

A string representing the description of the component.

=cut

has description =>
  ( isa => 'Str', is => 'ro', required => 1, reader => 'get_description' );

=pod

=head2 componentGroup

A string representing the Component Group alias that this component is part of.

=cut

has componentGroup => (
    isa      => 'NotNullStr',
    is       => 'ro',
    required => 1,
    reader   => 'get_componentGroup',
);

=pod

=head2 OKStatus

The status that the component is expected to have. It may be one or several (concatenated with a pipe character).

This attribute is required during object creation.

=cut

has OKStatus => (
    isa      => 'NotNullStr',
    is       => 'ro',
    reader   => 'get_OKStatus',
    required => 1
);

=pod

=head2 taskOKStatus

The expected tasks status of the component. It may be one or several (concatenated with a pipe character).

This attribute is required during object creation.

=cut

has taskOKStatus => (
    isa    => 'NotNullStr',
    is     => 'ro',
    reader => 'get_taskOKStatus',
    required => 1
);

=pod

=head2 criticality

A integer indicating how critical it is if the component does not have the expected status: the largest the number, 
the more critical it is.

=cut

has criticality => (
    isa      => 'Int',
    is       => 'ro',
    reader   => 'get_criticality',
    required => 1
);

=pod

=head1 METHODS

All attributes have their respective getter as C<get_><attribute name>.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon::Action::Check::Server>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
