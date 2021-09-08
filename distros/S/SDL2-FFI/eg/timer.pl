use strictures;
use lib '../lib';
use SDL2::FFI qw[:all];
sub DEFAULT_RESOLUTION() {1}
my $ticks = 0;

package No {
    use Moo;
    use Types::Standard qw[Int];
    has _meh => ( is => 'rw', isa => Int, default => 0 );
    sub meh { warn $_[0]->_meh( $_[0]->_meh + 1 ) }
}
my $zip;

sub callback {
    my ( $interval, $param ) = @_;
    $zip->meh;    # if $zip;
    SDL_Log( "Timer %d : param = %d\n", $interval, $param );
    $interval;
}

# Enable standard application logging
SDL_LogSetPriority( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO );
if ( SDL_Init(SDL_INIT_TIMER) < 0 ) {
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n", SDL_GetError() );
    exit;
}

# Start the timer
my $desired = DEFAULT_RESOLUTION;
my $t1      = SDL_AddTimer( $desired, \&ticktock );

# Wait 10 seconds
SDL_Log("Waiting 10 seconds\n");
SDL_Delay( 10 * 1000 );

# Stop the timer
SDL_RemoveTimer($t1);

# Print the results
if ($ticks) {
    SDL_Log( "Timer resolution: desired = %d ms, actual = %f ms\n",
        $desired, ( 10 * 1000 ) / $ticks );
}
$zip = No->new;

# Test multiple timers
SDL_Log("Testing multiple timers...\n");
$t1 = SDL_AddTimer( 100, \&callback, 1 );
$t1 ||
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "Could not create timer 1: %s\n", SDL_GetError() );
my $t2 = SDL_AddTimer( 50, \&callback, 2 );
$t2 ||
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "Could not create timer 2: %s\n", SDL_GetError() );
my $t3 = SDL_AddTimer( 233, \&callback, 3 );
$t3 ||
    SDL_LogError( SDL_LOG_CATEGORY_APPLICATION, "Could not create timer 3: %s\n", SDL_GetError() );

# Wait 10 seconds
SDL_Log("Waiting 10 seconds\n");
SDL_Delay( 10 * 1000 );
SDL_Log("Removing timer 1 and waiting 5 more seconds\n");
SDL_RemoveTimer($t1);
SDL_Delay( 5 * 1000 );
SDL_RemoveTimer($t2);
SDL_RemoveTimer($t3);
my $start = SDL_GetPerformanceCounter();

for ( 0 .. 1000000 ) {
    ticktock(0);
}
my $now = SDL_GetPerformanceCounter();
SDL_Log(
    "1 million iterations of ticktock took %f ms\n",
    ( ( $now - $start ) * 1000 ) / SDL_GetPerformanceFrequency()
);
SDL_Log( "Performance counter frequency: %f\n", SDL_GetPerformanceFrequency() );
my $start32 = SDL_GetTicks();
$start = SDL_GetPerformanceCounter();
SDL_Delay(1000);
$now = SDL_GetPerformanceCounter();
my $now32 = SDL_GetTicks();
SDL_Log(
    "Delay 1 second = %d ms in ticks, %f ms according to performance counter\n",
    ( $now32 - $start32 ),
    ( ( $now - $start ) * 1000 ) / SDL_GetPerformanceFrequency()
);
SDL_Quit();
exit;

sub ticktock {
    my ( $interval, $param ) = @_;
    ++$ticks;
    $interval;
}
