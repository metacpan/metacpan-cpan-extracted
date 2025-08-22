#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Easing::Stream;

my $time=time();
my $stream=Schedule::Easing::Stream->new(
	fh=>\*STDIN,
	input =>sub{foreach my $line (@_){print "At $time processed:  $line"}},
	update=>sub{$time=$_[0]//time()},
	# sleep =>4,
	# clock =>2,
	# batch =>10,
	# lines =>5,
	# regexp=>qr/(\d+)/,
);

print "Start time $time\n";
$stream->read();
print "End time $time at ",time(),"\n";
