use strict;
use warnings;
use Test2::V0;
use Test2::Tools::ClassicCompare qw[is_deeply];
use lib -d '../t' ? './lib' : 't/lib';
use lib '../lib', 'lib';
use SDL2::FFI qw[:all];
use experimental 'signatures';
$|++;
#
needs_display();

END {
    SDL_Quit();
}
bail_out 'Error initializing SDL: ' . SDL_GetError()
    unless SDL_Init( SDL_INIT_VIDEO | SDL_INIT_TIMER ) == 0;
my $done = 0;
my %timers;
$timers{1} = SDL_AddTimer(
    1000,
    sub ( $delay, $args ) {
        pass 'timer triggered without args';
        ok !defined $args, 'lack of timer args is correct';
        $done++;
        0;
    }
);
ok $timers{1}, 'SDL_AddTimer( ... ) without args returned id == ' . $timers{1};
#
$timers{2} = SDL_AddTimer(
    1000,
    sub ( $delay, $args ) {
        pass 'timer triggered with args';
        is $args, 'Yes!', 'timer args are correct';
        $done++;
        0;
    },
    'Yes!'
);
ok $timers{2}, 'SDL_AddTimer( ... ) with args returned id == ' . $timers{2};
#
$timers{3} = SDL_AddTimer(
    1000,
    sub ( $delay, $args ) {
        use Data::Dump;
        pass 'timer triggered with list of args';
        is_deeply $args, [ 'a', 'list' ], 'list of args are correct ([ \'a\', \'list\' ])';
        $done++;
        0;
    },
    [qw[a list]]
);
ok $timers{3}, 'SDL_AddTimer( ... ) with list of args returned id == ' . $timers{3};
#
$timers{4} = SDL_AddTimer(
    1000,
    sub ( $delay, $args ) {
        pass 'timer triggered with hashref of args';
        is_deeply $args, { a => 'list', time => 5 },
            'list of args are correct ({ a => \'list\', time => 5 })';
        $done++;
        0;
    },
    { a => 'list', time => 5 }
);
ok $timers{4}, 'SDL_AddTimer( ... ) with hash args returned id == ' . $timers{4};
#
$timers{5} = SDL_AddTimer(
    500,
    sub ( $delay, $args ) {
        fail 'timer triggered after being removed';
    },
    { a => 'list', time => 5 }
);
ok $timers{5}, 'SDL_AddTimer( ... ) with hash args returned id == ' . $timers{5};
diag 'Removing timer #5';
SDL_RemoveTimer( $timers{5} );
#
my $ping = 0;
$timers{6} = SDL_AddTimer(
    1,
    sub ( $delay, $args ) {
        if ( $ping == 0 ) {
            pass 'triggered 1 time';
            $ping++;
        }
        elsif ( $ping == 1 ) {
            pass 'triggered 2 times';
            $ping++;
            $done++;
            return 0;
        }
        else { fail 'triggered 3 times' }
        shift;
    }
);
ok $timers{6}, 'SDL_AddTimer( ... ) with hash args returned id == ' . $timers{6};
#
while (1) {
    SDL_Delay(1);
    last if $done == 5;
}
#
SDL_RemoveTimer($_) for sort values %timers;
#
done_testing;

sub needs_display {    # Taken from Test::NeedsDisplay but without Test::More

    # Get rid of Win32 and existing DISPLAY cases
    return 1 if $^O eq 'MSWin32';
    return 1 if $ENV{DISPLAY};

    # The quick way is to use the xvfb-run script
    diag 'No DISPLAY. Looking for xvfb-run...';
    my @PATHS = split $Config::Config{path_sep}, $ENV{PATH};
    foreach my $path (@PATHS) {
        my $xvfb_run = File::Spec->catfile( $path, 'xvfb-run' );
        next unless -e $xvfb_run;
        next unless -x $xvfb_run;
        diag 'Restarting with xvfb-run...';
        exec( $xvfb_run, $^X,
            ( $INC{'blib.pm'} ? '-Mblib' : () ),
            ( $INC{'perl5db.pl'} ? '-d' : () ), $0,
        );
    }

    # If provided with the :skip_all, abort the run
    if ( $_[1] and $_[1] eq ':skip_all' ) {
        plan( skip_all => 'Test needs a DISPLAY' );
        exit(0);
    }
    diag 'Failed to find xvfb-run.';
    diag 'Running anyway, but will probably fail...';
}
