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
		test => 'fetchtest',
	});

	unlink $test->client->tmpdir.'/01-atom.feedcache' if (-f $test->client->tmpdir.'/01-atom.feedcache');
	unlink $test->client->tmpdir.'/01-rss.feedcache' if (-f $test->client->tmpdir.'/01-rss.feedcache');

	POE::Kernel->run;

	is($test->cnt,42,'42 entries are received');
	
	ok(-f $test->client->tmpdir.'/01-atom.feedcache', "01-atom Cachefile exist");
	unlink $test->client->tmpdir.'/01-atom.feedcache';
	ok(-f $test->client->tmpdir.'/01-rss.feedcache', "01-rss Cachefile exist");
	unlink $test->client->tmpdir.'/01-rss.feedcache';

}

done_testing;
