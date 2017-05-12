#use Test::More qw( no_plan );
use Test::More tests => 11;

use Schedule::RateLimiter;
ok(1, 'Did the Schedule::RateLimiter module load?'); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


my $throttle = Schedule::RateLimiter->new( seconds => 60, iterations => 1 );
ok( ref( $throttle ), 'Did we construct an object?' );

is( $throttle->{seconds}, 60, 'Did the seconds value get set correctly?' );
is( $throttle->{iterations}, 1, 'Did the iterations value get set correctly?' );

$throttle = Schedule::RateLimiter->new( seconds => 60 );
is( $throttle->{iterations}, 1, 'Did the default iterations value get set correctly?' );

eval { $throttle = Schedule::RateLimiter->new() };
ok( $@ =~ /Missing 'seconds' argument/, 'Did we throw an error when seconds was missing?' );

eval { $throttle = Schedule::RateLimiter->new( seconds => 30, iterations => 1.000005 ) };
ok( $@ =~ /'iterations' argument must be integer/, "Did we throw an error when iterations was fractional? $@" );

eval { $throttle = Schedule::RateLimiter->new( seconds => 30, iterations => -10 ) };
ok( $@ =~ /'iterations' argument must be positive/, 'Did we throw an error when iterations was negative?' );

eval { $throttle = Schedule::RateLimiter->new( seconds => 30, iterations => 'ten' ) };
ok( $@ =~ /'iterations' argument must be numeric/, 'Did we throw an error when iterations was a string?' );

eval { $throttle = Schedule::RateLimiter->new( seconds => 30, iterations => '1 hundred' ) };
ok( $@ =~ /'iterations' argument must be numeric/, 'Did we throw an error when iterations was numeric and string?' );

eval { $throttle = Schedule::RateLimiter->new( seconds => 'thirty' ) };
ok( $@ =~ /'seconds' argument must be numeric/, "Did we throw an error when seconds was a string? $@" );

