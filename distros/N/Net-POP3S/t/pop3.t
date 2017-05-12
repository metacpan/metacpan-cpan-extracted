# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl pop3.t'

#########################

use strict;
use warnings;

use Test::More;

use Net::Config;

BEGIN { require_ok('Socket') or
	diag("I don't believe that the missing of Socket"); }
BEGIN { use_ok('Net::POP3S'); }

#########################

SKIP: {
	skip "No suitable testing server given (NetConfig).", 3
		unless (@{$NetConfig{pop3_hosts}} && $NetConfig{test_hosts});

	my $pop = Net::POP3S->new(Debug => 0);
	ok( defined($pop),	'create Net::POP3S object');

	ok( $pop->banner,	'getting sever reply');


	ok ( $pop->quit,	'closing connection');
}

done_testing;
