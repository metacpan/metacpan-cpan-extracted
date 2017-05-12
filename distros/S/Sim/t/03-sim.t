use Test::More tests => 2;
use Sim;

{
    my $res;
    Sim->schedule(
        0.2 => sub { $res .= "Hi\n" },
        0.4 => sub {
            Sim->schedule(
                0.5 => sub { $res .= "Wow!\n" },
                Sim->now + 0.2 => sub { $res .= "Hello!\n" },
            );
        },
        0.5 => sub { $res .= "now is " . Sim->now . "\n"; },
    );
    Sim->run( fires => 15 );
    $res .= "now is " . Sim->now . "\n";  # now is 0.6

    is $res, <<'_EOC_';
Hi
now is 0.5
Wow!
Hello!
now is 0.6
_EOC_
}

{
    my $res;
    Sim->reset;
    Sim->schedule(
        0.2 => sub { $res .= "Hi\n" },
        0.4 => sub {
            Sim->schedule(
                0.5 => sub { $res .= "Wow!\n" },
                Sim->now + 0.2 => sub { $res .= "Hello!\n" },
            );
        },
        0.5 => sub { $res .= "now is " . Sim->now . "\n"; },
    );
    Sim->run( duration => 1.0 );  # upper-limit for simulation time
    $res .= "now is " . Sim->now . "\n";  # now is 0.6

    is $res, <<'_EOC_';
Hi
now is 0.5
Wow!
Hello!
now is 0.6
_EOC_
}

