package Siebel::COM::Business;

use strict;
use Win32::OLE 0.17;
use Moose 2.1604;
use MooseX::FollowPBP 0.05;
use namespace::autoclean 0.25;

with 'Siebel::COM';
our $VERSION = '0.3'; # VERSION

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Siebel::COM::Business - superclass for all Siebel COM Business related objects

=head1 DESCRIPTION

This superclass doesn't do anything else than define default behaviour for all subclasses of it. These default behaviour includes:

=over

=item *

usage of L<Siebel::COM> role

=item *

enable default attributes accessories as defined by L<MooseX::FollowPBP>.

=back

Unless you're extending something you really don't have much to do with it.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM>

=item *

L<MooseX::FollowPBP>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel COM project.

Siebel COM is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel COM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel COM.  If not, see <http://www.gnu.org/licenses/>.

=cut
