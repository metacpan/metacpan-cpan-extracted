#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More 0.88;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j::Driver::Plugin::LWP;
use Neo4j::Driver 0.34;

my $driver = Neo4j::Driver->new;

plan tests => 2 + 3 + $no_warnings;

ok my $plugin = Neo4j::Driver::Plugin::LWP->new, 'new plug-in';
ok $driver->plugin($plugin), 'register plug-in';

SKIP: {
	# To check whether registering the plug-in was successful, we need to use
	# private driver internals to retrieve a reference to the experimental
	# event manager. This may break with future driver versions.
	my $events = eval { $driver->{events} // $driver->{plugins} };
	
	skip 'looks like driver internals have changed', 3
		unless eval { $events->isa('Neo4j::Driver::Events') };
	
	ok my $net = $events->trigger( http_adapter_factory => $driver ), 'http_adapter_factory event succeeds';
	is ref $net, 'Neo4j::Driver::Net::HTTP::LWP', 'http_adapter_factory result';
	is $net->VERSION, $plugin->VERSION, 'loaded net adapter version matches plug-in version';
}

done_testing;
