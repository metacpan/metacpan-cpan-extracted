#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async::Loop;
use Ryu::Async;

use Log::Any::Adapter qw(Stdout), log_level => 'trace';

my $loop = IO::Async::Loop->new;
$loop->add(
	my $ryu = Ryu::Async->new
);

{
	my $timer = $ryu->timer(
		interval => 0.10,
	)->take(10)
	 ->each(sub { print "tick\n" });
	warn $timer->describe;
	$timer->get;
}
