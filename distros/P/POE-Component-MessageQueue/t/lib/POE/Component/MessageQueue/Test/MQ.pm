#
# Copyright 2007, 2008 Paul Driver <frodwith@gmail.com>
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

package POE::Component::MessageQueue::Test::MQ;
use strict;
use warnings;

use POE::Component::MessageQueue::Test::ForkRun;
use Exporter qw(import);
our @EXPORT = qw(start_mq stop_fork);

sub start_mq {
	my %options = @_;
	my $storage = delete $options{storage} || 'BigMemory';
	my $storage_args = delete $options{storage_args} || {};
	start_fork(sub {
		use POE;
		use POE::Component::MessageQueue;
		use POE::Component::MessageQueue::Logger;
		use POE::Component::MessageQueue::Storage::Memory;
		use POE::Component::MessageQueue::Test::EngineMaker;

		# required for scripts which call start_mq() more than once.
		$poe_kernel->stop();

		if (ref $storage eq 'CODE') {
			$storage = $storage->(%$storage_args);
		} else {
			$storage = make_engine($storage, $storage_args);
		}

		my %defaults = (
			port    => 8099,
			storage => $storage,
			logger  => POE::Component::MessageQueue::Logger->new(level=>7),
		);

		$defaults{$_} = $options{$_} foreach (keys %options);

		POE::Component::MessageQueue->new(%defaults);
	});
}

1;
