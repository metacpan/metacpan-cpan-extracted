package Example::Service::Factor;

use Myriad::Service;

has $factor = 0;
has $players_id;

async method diagnostics ($level) {
    return 'ok';
}

async method secret_checks : Receiver(service => 'example.service.secret') ($sink) {
    $players_id ||= {};
    return $sink->map(
        async sub {
            my $e = shift;
            my %info = ($e->@*);
            $log->tracef('INFO %s', \%info);
            my $data = $info{'data'};
            my $secret_service = $api->service_by_name('example.service.secret');
            my $secret_storage = $secret_service->storage;

            # If pass reset the game, with new value.
            if($data->{pass}) {
                $factor = 0;
                $players_id = {};
                await $secret_service->call_rpc('reset_game', secret => int(rand(100)));
                $log->info('Called RESET');
            } else {
                # We will:
                # Double the factor on every new player joining
                # increment factor by number of player trials on every check.
                my $player_id = $data->{id};
                my $trials = await $secret_storage->hash_get('current_players',$player_id);

                # since there is no hash_count implemented yet.
                $players_id->{$player_id} = 1;

                $log->tracef('TRIALS: %s, MILT: %s', $trials, scalar keys %$players_id);
                $factor += $trials;
                $factor *= 2 for keys %$players_id;

            }
            $log->infof('Setting factor %d', $factor);
            await $api->storage->set('factor', $factor);
        }
    )->resolve;
}

1;


