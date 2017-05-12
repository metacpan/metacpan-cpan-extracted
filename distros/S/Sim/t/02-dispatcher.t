use strict;
use warnings;

use Test::More tests => 10;
use Sim::Clock;
use Sim::Dispatcher;

my $clock = Sim::Clock->new;
my $disp = Sim::Dispatcher->new(clock => $clock);

#warn "HERE!";
my $i = 0;
my $hdl;
$hdl = sub {
    #warn "i = $i\n";
    $i++;
    $disp->schedule($disp->now + 1 => $hdl);
};
#warn "THERE!";
$disp->schedule(3 => $hdl);
#warn "HI!";
$disp->run(fires => 5);
is $i, 5, 'counter worked as expected';
is $disp->now, 7, 'now is 7';
$disp->reset;
is $disp->time_of_next, undef, 'queue is empty';
is $disp->now, 0, 'clock reset';
#warn "YO!";
#print $i;

$disp->reset;
$i = 0;
is $disp->now, 0, 'clock reset';
is $disp->time_of_next, undef, 'queue reset';
$disp->schedule(3 => $hdl);
$disp->run(duration => 5);
is $i, 3, 'counter works for duration 5';

{
    my $clock = Sim::Clock->new;
    # you can also use your own Clock instance here
    my $engine = Sim::Dispatcher->new(clock => $clock);

    # Example 1: Static scheduling

    my $res;
    $engine->schedule(
       0 => sub { $res .= $engine->now . ": morning!\n" },
       1 => sub { $res .= $engine->now . ": afternoon!\n" },
       5 => sub { $res .= $engine->now . ": night!\n" },
    );
    $engine->run( duration => 50 );
    # or Sim::Dispatcher->run( fires => 5 );

    is $res, <<'_EOC_';
0: morning!
1: afternoon!
5: night!
_EOC_

    $engine->reset();

    # Example 2: Dynamic (recursive) sch
    my ($count, $handler);

    # event handler:
    $handler = sub {
        $count++;
        my $time_for_next = $engine->now() + 2;
        $engine->schedule(
            $time_for_next => $handler,
        );
    };
    # only schedule the "seed" event
    $engine->schedule(
        0.5 => $handler,
    );
    $engine->run( fires => 5 );
    is $count, 5;
    is $engine->now(), 8.5;
}

