#use Test::More qw( no_plan );
use Test::More tests => 22;

use Schedule::RateLimiter;
ok(1, 'Did the Schedule::RateLimiter module load?'); # If we made it this far, we're ok.

#########################

my $throttle = Schedule::RateLimiter->new( seconds => 0, iterations => 1 );
ok ( ref( $throttle ), 'Did we build a zero-second Schedule::RateLimiter?' );

for ( 1.. 20 ) {
    ok ( $throttle->event(block => 0), "Test 0-second Throttle: $_" );
}

