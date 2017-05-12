#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
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

package POE::Component::MessageQueue::Subscription;
use Moose;

has client => (
	is       => 'ro',
	isa      => 'POE::Component::MessageQueue::Client',
	weak_ref => 1,
	required => 1,
);

has destination => (
	is       => 'ro',
	does     => 'POE::Component::MessageQueue::Destination',
	weak_ref => 1,
	required => 1,
);

has client_ack => (
	is       => 'ro',
	default  => 0,
);

has ready => (
	is      => 'rw',
	default => 1,
);

# Ready will always return true if client_ack is false.
around ready => sub {
	my $original = shift;
	my $self = shift;

	return $original->($self, @_) if (@_ || $self->client_ack);

	return 1;
};

__PACKAGE__->meta->make_immutable();

1;
