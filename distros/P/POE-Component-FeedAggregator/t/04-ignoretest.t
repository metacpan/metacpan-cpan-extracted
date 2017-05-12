#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Cwd;
use File::Spec::Functions;

use FindBin qw($Bin);
use lib "$Bin/lib";

SKIP: {
	eval { require POE::Component::Server::HTTP };

	skip "You need POE::Component::Server::HTTP installed", 1 if $@;

	require Test::PoCoFeAg::TestDaemon;
	Test::PoCoFeAg::TestDaemon->import;

	my $test = Test::PoCoFeAg::TestDaemon->new({
		data_path => catdir( getcwd(), 't', 'data' ),
		port => $ENV{POE_COMPONENT_FEEDAGGREGATOR_TEST_PORT} ? $ENV{POE_COMPONENT_FEEDAGGREGATOR_TEST_PORT} : 63223,
		test => 'ignoretest',
	});

	unlink $test->client->tmpdir.'/04-atom.feedcache' if (-f $test->client->tmpdir.'/04-atom.feedcache');

	POE::Kernel->run;

	is($test->cnt,0,'0 entries are received after 10 seconds (which are probably 4-5 feed checks)');

	ok(-f $test->client->tmpdir.'/04-atom.feedcache', "04-atom Cachefile exist");
	unlink $test->client->tmpdir.'/04-atom.feedcache';
}

done_testing;
