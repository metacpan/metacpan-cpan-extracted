# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl smtp.t'

#########################

use strict;
use warnings;

use Test::More;

use Net::Config;

BEGIN { require_ok('Socket') or
	diag("I don't believe that the missing of Socket"); }
BEGIN { use_ok('Net::SMTPS'); }

#########################

SKIP: {
	skip "No suitable testing server given (NetConfig).", 3
		unless (@{$NetConfig{smtp_hosts}} && $NetConfig{test_hosts});

	my $smtp = Net::SMTPS->new(Debug => 0);
	ok( defined($smtp),	'create Net::SMTPS object');

	ok( $smtp->domain,	'getting sever reply');

	ok ( $smtp->quit,	'closing connection');
}

done_testing;
