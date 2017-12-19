#!/usr/bin/env perl

use Test::Most tests => 1;
use Test::Requires qw(ZMQ::LibZMQ4 ZMQ::Constants);

use lib 't/lib';
use ReverseEcho;

subtest "Reverse echo" => sub {
	my $n_msgs = 3;
	my $blobs = ReverseEcho->run('ZMQ::LibZMQ4', $n_msgs);

	is_deeply($blobs, [
		map { "hello $_" } (0..$n_msgs-1)
	], "Got the $n_msgs messages" );
};

done_testing;
