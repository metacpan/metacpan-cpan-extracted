use strict;
use warnings;


use threads;
use threads::shared;
use Time::HiRes qw( gettimeofday tv_interval );

my $running :shared = 1; 
my $threads = $ARGV[0] || 1;

my $bailout = 10000000;

my $start = [gettimeofday];
my @threads;
for ( 1..$threads ) {
	
	push @threads, 
		async {
			compute_sublime($running);
		};
}

# Poll 
while ( threads->list( threads::running )  && threads->list( threads::joinable ) ){
	$_->join for threads->list( threads::joinable );
	sleep 1;
}


my $finish = [gettimeofday];
my $loop_running_time = tv_interval( $start , $finish );

warn "Ran to completion in $loop_running_time\n"; 

sub compute_sublime {
	my $running = shift;
	my $iv = 1;
	my $result;
	while ( $running && $iv < $bailout ) {
		$result = sin($iv);
		$iv++;
	}
	
}
