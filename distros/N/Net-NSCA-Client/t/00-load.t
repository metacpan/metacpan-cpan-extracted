#!perl -T
# This test represents the way Ovid has suggested
# http://use.perl.org/~Ovid/journal/39859
# but modified to use Test::More instead of Test::Most

use strict;
use warnings 'all';

use Test::More;

diag(sprintf 'Perl %s', $]);

eval {
	use Moose ();
	use Class::MOP ();

	diag(sprintf 'Moose %s', $Moose::VERSION);
	diag(sprintf 'Class::MOP %s', $Class::MOP::VERSION);
};

BEGIN {
	my @modules = qw(
		Net::NSCA::Client
		Net::NSCA::Client::Connection
		Net::NSCA::Client::Connection::TLS
		Net::NSCA::Client::DataPacket
		Net::NSCA::Client::InitialPacket
		Net::NSCA::Client::Library
		Net::NSCA::Client::ServerConfig
		Net::NSCA::Client::Utils
	);

	# Plan tests of the number of modules
	plan tests => scalar @modules;

	# Attempt to use every module
	foreach my $module (@modules) {
		use_ok($module) or BAIL_OUT("Unable to load $module");
	}
}
