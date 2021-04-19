package example::Service::Secret;

use Myriad::Service;
use Ryu::Source;
use Future::Utils qw( fmap_void );

has $secret = $ENV{'SECRET'};
has $check_event_handler = Ryu::Source->new;

# temporarily until we add more operations to storage.
has $ids = {};

async method diagnostics ($level) {
    return 'ok';
}

async method check : RPC (%args) {
    my ($id, $value) = map { $args{$_} } qw(id value);
    $ids->{$id} = 1;
    # If it was not set by ENV
    $secret = int(rand(100)) unless $secret;

    # Get Factor of difference that will be allowed.
    my $factor_storage = $api->service_by_name('example.service.factor')->storage;
    my $factor = await $factor_storage->get('factor');
    $factor = 0 unless $factor;

    # Get player previous trials info
    my $storage = $api->storage;
    my $trials = await $storage->hash_get('current_players', $id);
    $trials = 0 unless $trials;

    $log->debugf('Received check call. ID: %d | Value: %d | Secret: %d | Factor: %d', $id, $value, $secret, $factor);
    my $res = {answer => 'Wrong', factor => $factor, hint => '', id => $id, value => $value, trials => ++$trials};

    # Check if player guessed the secret; allowing a margin of difference(factor)
    my $diff = $value - $secret;
    if (abs($diff) <= $factor) {
        $res->{answer} = 'Correct';
    } elsif ($diff < 0 ) {
        $res->{hint} = 'guess higher';
    } else {
        $res->{hint} = 'guess lower';
    }

    # Update player trials.
    await $storage->hash_set('current_players', $id, $trials);
    $check_event_handler->emit($res);
    return  $res;

}

async method reset_game : RPC (%args) {
    # Storage not yet impleminting DEL or HGETALL hence
    my $res = await fmap_void( async sub {
        my $id = shift;
        await $api->storage->hash_set('current_players', $id, 0);
    }, foreach => [keys $ids->%*], concurrent => 10);
    $secret = $args{'secret'};

    return {reset_done => 1} unless defined $res;
}

async method secret_checks : Emitter() ($source){
    $check_event_handler->each(sub {
        my $res = shift;
        my $pass = $res->{answer} eq 'Correct' ? 1 : 0;
        my $event = {pass => $pass, id => $res->{id}};
        $source->emit($event);
    });
}

1;
