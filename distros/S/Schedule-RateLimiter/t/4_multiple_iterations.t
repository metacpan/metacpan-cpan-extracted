#use Test::More qw( no_plan );
use Test::More tests => 202;

use Schedule::RateLimiter;
ok(1, 'Did the Schedule::RateLimiter module load?'); # If we made it this far, we're ok.

#########################

my $throttle = Schedule::RateLimiter->new( seconds => 99999999, iterations => 100 );
ok ( ref( $throttle ), 'Did we build an Schedule::RateLimiter with more than one iteration?' );
for ( 1 .. 100 ) {
    ok ( $throttle->event( block => 0 ), "Was event $_ allowed to run?" );
}
for ( 101 .. 200 ) {
    ok (! $throttle->event( block => 0 ), "Was event $_ dis-allowed to run?" );
}




