package Coffee::Drinker::Heavy;

use Myriad::Service;

use JSON::MaybeUTF8 qw(:v1);
use String::Random;
use Future::Utils qw( fmap_concat fmap_void );

has $rng = String::Random->new;
has $latest_user_id;
has $latest_machine_id;

async method startup () {
    my $user_storage    = $api->service_by_name('coffee.manager.user')->storage;
    my $machine_storage = $api->service_by_name('coffee.manager.machine')->storage;

    $latest_user_id    = await $user_storage->get('id');
    $latest_machine_id = await $machine_storage->get('id');

}

async method drink : Batch () {
    my $coffee_service = $api->service_by_name('coffee.manager.coffee');
    my @got_coffees;
    my $concurrent = int(rand(51));
    if ( $latest_user_id > 2 and $latest_machine_id > 2 ) {
        my $get_coffee_params = sub { return { int(rand($latest_user_id))  => int(rand($latest_machine_id)) } };
        my $requests = [ map { $get_coffee_params->() } (0..$concurrent) ];
        $log->warnf('Bought Coffee User: %d | Machine: %d | entry_id: %d', $get_coffee_params->());
        @got_coffees = await &fmap_concat( $self->$curry::curry(async method ($params) {
            my $r = await $coffee_service->call_rpc('buy', 
                type => 'PUT',
                params => $params
            );
            $log->warnf('Bought Coffee User: %d | Machine: %d | entry_id: %d', $params->%*, $r->{id});
            #push @got_coffees,  $r;
            $r;
        }), foreach => $requests, concurrent => $concurrent);
    }
    return  [ @got_coffees ];

}

async method new_drinker : Batch () {
    my $user_service = $api->service_by_name('coffee.manager.user');
    my $concurrent = int(rand(51));
    my $requests = [ map { {login => $rng->randpattern("CccccCcCC"), password => 'pass', email => $rng->randpattern("CCCccccccc")} } (0..$concurrent) ];
    my @added_users = await &fmap_concat( $self->$curry::curry(async method ($user_hash) {
            my $r = await $user_service->call_rpc('request', 
                type => 'PUT',
                body => $user_hash
            );
            $log->warnf('Added User: %s', $r);
            $latest_user_id = $r->{id};
            $r;
        }), foreach => $requests, concurrent => $concurrent);

    return  [ @added_users ];

}

async method new_machine : Batch () {
    my $machine_service = $api->service_by_name('coffee.manager.machine');
    my $concurrent = int(rand(51));
    my $requests = [ map { {name => $rng->randpattern("Ccccccccc"), caffeine => $rng->randpattern("n")} } (0..$concurrent) ];
    my @added_machines = await &fmap_concat( $self->$curry::curry(async method ($machine_hash) {
            my $r = await $machine_service->call_rpc('request', 
                type => 'PUT',
                body => $machine_hash
            );
            $log->warnf('Added Machine %s | %s', $r, $machine_hash);
            $latest_machine_id = $r->{id};
            $r;
        }), foreach => $requests, concurrent => $concurrent);

    return  [ @added_machines ];
}

1;
