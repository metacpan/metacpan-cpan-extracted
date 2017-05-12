#
# Copyright 2010 David Snopek <dsnopek@gmail.com>
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

package POE::Component::MessageQueue::Test::DBI;
use strict;
use warnings;

use POE::Component::MessageQueue::Storage::DBI;
use Test::More;
use Exporter 'import';

our @EXPORT = qw(
	check_environment_vars_dbi
	clear_messages_dbi
	storage_factory_dbi
);

use constant {
	DSN      => 'POCOMQ_TEST_DSN',
	USERNAME => 'POCOMQ_TEST_USERNAME',
	PASSWORD => 'POCOMQ_TEST_PASSWORD',
};

# This test requires an external (not SQLite) database to work.  The user must setup
# this database in advance of the test or it will be skipped.
sub check_environment_vars_dbi {
	if (!defined $ENV{+DSN}) {
		plan skip_all => "This test requires an external database (with correct tables already defined).  Set the following environment variables to cause the test to run: ". join(', ', DSN, USERNAME, PASSWORD);
		exit 0;
	}
}

sub clear_messages_dbi {
	# clean database
	DBI->connect($ENV{+DSN}, $ENV{+USERNAME}, $ENV{+PASSWORD})
	   ->do("DELETE FROM messages");
}

sub storage_factory_dbi {
	my %args1 = @_;
	my $storage = sub {
		my %args2 = @_;
		return POE::Component::MessageQueue::Storage::DBI->new(
			dsn      => $ENV{+DSN},
			username => $ENV{+USERNAME},
			password => $ENV{+PASSWORD},
			%args1,
			%args2,
		);
	};
}

