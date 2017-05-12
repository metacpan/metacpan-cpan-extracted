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

package POE::Component::MessageQueue::Test::EngineMaker;
use strict;
use warnings;

use Exporter qw(import);
use File::Temp qw(tmpnam);
use POE::Component::MessageQueue::Storage::Default;
our @EXPORT = qw(
	make_engine engine_names make_db engine_package DATA_DIR LOG_LEVEL
);

my $data_dir = tmpnam();

sub DATA_DIR { 
	if (my $dir = shift) {
		$data_dir = $dir;
	}
	return $data_dir;
}
sub DB_FILE { DATA_DIR.'/mq.db' }
sub DSN { 'DBI:SQLite:dbname='.DB_FILE }

my $level = 7;
sub LOG_LEVEL {
	if (my $nl = shift) {
		$level = $nl;
	}
	return $level;
}

my %engines = (
	DBI        => {
		args    => sub {(
			dsn      => DSN,
			username => q(),
			password => q(),
		)},
	},
	FileSystem => {
		args     => sub {(
			info_storage => make_engine('DBI'),
			data_dir     => DATA_DIR,
		)},
	},
	Throttled  => {
		args    => sub {(
			throttle_max => 2,
			back         => make_engine('FileSystem'),
		)},
	},
	Complex    => {
		args    => sub {(
			timeout     => 4,
			granularity => 2,
			front_max   => 1024,
			front       => make_engine('BigMemory'),
			back        => make_engine('Throttled'),
		)}
	},
	Remote     => {
		args    => sub {(
			servers => [{host => 'localhost', port => 9321}],
		)},
	},
	BigMemory => {},
	Memory    => {},
);

sub engine_package {'POE::Component::MessageQueue::Storage::'.shift} 
sub engine_names { keys %engines }

sub make_engine {
	my ($name, $extra) = @_;
	my $eargs = $engines{$name}->{args} || sub {};
	my %args = $eargs->();
	if (defined $extra) {
		%args = ( %args, %$extra );
	}
	return engine_package($name)->new(%args,
		logger => POE::Component::MessageQueue::Logger->new(level=>LOG_LEVEL),
	);
}

sub make_db {
	POE::Component::MessageQueue::Storage::Default::_make_db(
		DB_FILE, DSN, q(), q());
}

1;
