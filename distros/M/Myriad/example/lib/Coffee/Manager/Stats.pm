package Coffee::Manager::Stats;

use Myriad::Service;

async method startup () {

}

async method new_user : Receiver(service => 'coffee.manager.user', channel => 'new_user') ($sink) {
    return $sink->map(sub {
        my $user = shift;
        $log->warnf('GOT new_user %s', $user);
        # Storage ZADD new_user epoch $user

    });
}

async method new_machine : Receiver(service => 'coffee.manager.machine', channel => 'new_machine') ($sink) {
    return $sink->map(sub {
        my $machine = shift;
        $log->warnf('GOT new_machine %s', $machine);
        # Storage ZADD new_machine epoch $machine

    });
}

async method new_coffee : Receiver(service => 'coffee.manager.coffee', channel => 'new_coffee') ($sink) {
    return $sink->map(sub {
        my $coffee = shift;
        $log->warnf('GOT new_coffee %s', $coffee);
        # Storage ZADD new_coffee epoch $coffee
        # Storage ZADD user_$userid_coffee epoch $coffee
        # Storage ZADD machine_$machid_coffee epoch $coffee

    });
}

async method stats : RPC (%args) {
    my $for = $args{for} // 'all';
    my $result;
    if ( $for eq 'user' or $for eq 'all' ) {
        # Total users
        # users per hour
        # Top Coffee drinkers
        # highest caffeine level for users
    }

    if ( $for eq 'machine' or $for eq 'all' ) {
        # Total Machines
        # Machines per hour
        # Top machine sellers
    }
 
    if ( $for eq 'coffee' or $for eq 'all' ) {
        # Total coffee
        # Coffee's per hour
    }

    return $result;
}

async method user_stats : RPC (%args) {
    my $user_id = $args{user_id};

    # user stats
    # per hour and overall
}

async method machine_stats : RPC (%args) {
    my $machine_id = $args{machine_id};

    # user stats
    # per hour and overall
}
1;
