#
# Copyright 2007 Paul Driver <frodwith@gmail.com>
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

package POE::Component::MessageQueue::Destination;
use Moose::Role;

has parent => (
	is       => 'ro',
	required => 1,
	handles  => [qw(log notify storage dispatch_message)],
);

has subscriptions => (
	is       => 'rw',
	isa      => 'HashRef[POE::Component::MessageQueue::Subscription]',
	default  => sub { {} },
	traits   => ['Hash'],
	handles  => {
		'set_subscription'    => 'set',
		'get_subscription'    => 'get',
		'delete_subscription' => 'delete',
		'all_subscriptions'   => 'values',
	},
);

has name => (
	is       => 'ro',
	required => 1,
);

requires qw(send is_persistent pump shutdown);

1;

