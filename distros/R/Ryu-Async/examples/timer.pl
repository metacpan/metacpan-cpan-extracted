#!/usr/bin/env perl 
use strict;
use warnings;
use feature qw(say);

use IO::Async::Loop;
use Ryu::Async;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $ryu = Ryu::Async->new
);

$ryu->timer(interval => 0.5)
	->take(4)
	->each(sub {
		say " * tick"
	})
	->get;

