package Siebel::Srvrmgr::Comps_source;

=pod

=head1 NAME

Siebel::Srvrmgr::Comps_source - Moose Role for classes that exposes Siebel Server components information

=head1 DESCRIPTION

This module is a L<Moose::Role>.

It is intended to be used by classes that will offer information about Siebel Server components by using instances of L<Siebel::Srvrmgr::OS::Process>.

By applying this role, it is required that classes provides an implementation of the method C<find_comps>. The object of such method is to merge information
from the operational system with the Siebel Server components available.

This method expects as parameter a hash reference, being the keys the PID's of Siebel processes and the values instances of L<Siebel::Srvrmgr::OS::Process> or
subclasses of it.

The hash reference items will be updated and the same reference will be returned. 

=cut

use warnings;
use strict;
use Moose::Role 2.1604;

requires 'find_comps';
our $VERSION = '0.29'; # VERSION

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::OS::Process>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
