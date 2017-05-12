#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Cwd;
use File::Spec::Functions;
use IO::All;

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
		test => 'counttest',
	});

	unlink $test->client->tmpdir.'/03-atom.feedcache' if (-f $test->client->tmpdir.'/03-atom.feedcache');

	POE::Kernel->run;

	is($test->cnt,21,'21 entries are received');

	ok(-f $test->client->tmpdir.'/03-atom.feedcache', "03-atom Cachefile exist");
	
	my @lines = io($test->client->tmpdir.'/03-atom.feedcache')->slurp;
	
	my $count = @lines;

	is($count, 10, "03-atom Cachefile has just 10 lines");
	
	unlink $test->client->tmpdir.'/03-atom.feedcache';
}

done_testing;
