#!perl -w
use strict;
use Ruby -all;
use threads;

sub thr{
	my $i = 0;
	for(1 .. 10){
		Thread->new(sub{
			puts $i;
		});
	}
}

my @thr;
for(1 .. 5){
	push @thr, threads->new(\&thr);
}

for(reverse @thr){
	$_->join();
}
