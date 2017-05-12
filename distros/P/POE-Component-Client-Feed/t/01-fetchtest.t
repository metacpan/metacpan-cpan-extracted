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

	require Test::PoCoClFe::TestDaemon;
	Test::PoCoClFe::TestDaemon->import;

	my $test = Test::PoCoClFe::TestDaemon->new({
		data_path => catdir( getcwd(), 't', 'data' ),
		port => $ENV{POE_COMPONENT_CLIENT_FEED_TEST_PORT} ? $ENV{POE_COMPONENT_CLIENT_FEED_TEST_PORT} : 63221,
	});

	POE::Kernel->run;

	is($test->atom_cnt,21,'Atom Feed with 21 entries is received');
	is($test->rss_cnt,21,'RSS Feed with 21 entries is received');
}

done_testing;
