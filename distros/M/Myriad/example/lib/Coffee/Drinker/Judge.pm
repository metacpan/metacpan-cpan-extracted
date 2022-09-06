package Coffee::Drinker::Judge;

use Myriad::Service;

use Time::Moment;
use IO::Async::Timer::Periodic;

has $current_users;
has $current_machines;
has $current_coffee;
has $start_time;
has $timer;

async method startup () {
    $current_users = [];
    $current_machines = [];
    $current_coffee = [];
    $start_time = Time::Moment->now;

    $self->add_child(
        $timer = IO::Async::Timer::Periodic->new(
            interval => 4,
            on_tick => sub {
                my $now = Time::Moment->now;

                $log->infof('Running for: %d (seconds)', $start_time->delta_seconds($now) );
                $log->infof('Current Count: Users: %d | Machines: %d | Coffee: %d', scalar @$current_users, scalar @$current_machines, scalar @$current_coffee);
            },
        )
    );
    $timer->start;
}

async method drinking_tracker : Receiver(service => 'coffee.drinker.heavy', channel => 'drink') ($sink) {
    return $sink->map(sub {
        my $coffee = shift;
        $log->infof('GOT COFFEE %s', $coffee);
        push @$current_coffee, $coffee;
    });
}

async method drinkers_tracker : Receiver(service => 'coffee.drinker.heavy', channel => 'new_drinker') ($sink) {
    return $sink->map(sub {
        my $user = shift;
        $log->infof('GOT new Drinker %s', $user);
        push @$current_users, $user;
    });
}

async method machine_tracker : Receiver(service => 'coffee.drinker.heavy', channel => 'new_machine') ($sink) {
    return $sink->map(sub {
        my $machine = shift;
        $log->infof('GOT new MACHINE %s', $machine);
        push @$current_machines, $machine;
    });
}
1;
