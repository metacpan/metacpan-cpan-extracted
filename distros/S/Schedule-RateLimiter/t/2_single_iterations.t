#use Test::More qw( no_plan );
use Test::More tests => 11;

use Schedule::RateLimiter;
ok(1, 'Did the Schedule::RateLimiter module load?'); # If we made it this far, we're ok.

#########################


# Blocking mode unspecified (default: blocking)
my $throttle = Schedule::RateLimiter->new( seconds => 999999, iterations => 1 );

ok( $throttle->event( block => 0 ), 'Did the first event return success?' );

ok( ! $throttle->event( block => 0 ), 'Did the second event fail?' );

eval { local $SIG{ALRM}= sub{ die 'alarm1' }; alarm( 2 ); $throttle->event(); alarm( 0 ) };
ok( $@ =~ /alarm1/i, "Did an implicit blocking event hang?" );

eval { local $SIG{ALRM}= sub{ die 'alarm2' }; alarm( 2 ); $throttle->event( block => 1); alarm( 0 ) };
ok( $@ =~ /alarm2/i, "Did an explicit blocking event hang?" );

# Blocking mode specified to block.
$throttle = Schedule::RateLimiter->new( seconds => 999999, iterations => 1, block => 1 );

ok( $throttle->event( block => 0 ), 'Did the first event return success?' );

ok( ! $throttle->event( block => 0 ), 'Did the second event fail?' );

eval { local $SIG{ALRM}= sub{ die 'alarm1' }; alarm( 2 ); $throttle->event(); alarm( 0 ) };
ok( $@ =~ /alarm1/i, "Did an implicit blocking event hang when blocking is explicitly on?" );


# Blocking mode specified to non-block.
$throttle = Schedule::RateLimiter->new( seconds => 999999, iterations => 1, block => 0 );

ok( $throttle->event( block => 0 ), 'Did the first event return success?' );

ok( ! $throttle->event( block => 0 ), 'Did the second event fail?' );

eval { local $SIG{ALRM}= sub{ die 'alarm3' }; alarm( 10 ); $throttle->event(); alarm( 0 ) };
ok( $@ !~ /alarm3/i, "Did an implicit non-blocking event hang?" );

