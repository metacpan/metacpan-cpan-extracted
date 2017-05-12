#
# Copyright 2007, 2008, 2009 Paul Driver <frodwith@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::MessageQueue::IDGenerator;
use Moose::Role;

requires qw(generate);

1;

=head1 NAME

POE::Component::MessageQueue::IDGenerator - Role for id generators.

=head1 DESCRIPTION

This can't be used directly, but just defines the interface for ID
generators.

=head1 METHODS

=over 4

=item new

Returns a new instance of the ID generator.  You should do any seeding,
reading from persistence, or whatnot here.

=item generate => SCALAR

Returns some kind of unique string.  

=back

SEE ALSO

L<POE::Component::MessageQueue::Message::ID>

=head1 AUTHOR

Paul Driver <frodwith@gmail.com>
