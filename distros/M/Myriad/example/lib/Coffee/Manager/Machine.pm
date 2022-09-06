package Coffee::Manager::Machine;

use Myriad::Service;

use JSON::MaybeUTF8 qw(:v1);
use Ryu::Source;

has $fields;
has $last_id;
has $new_machine_handler = Ryu::Source->new;

BUILD (%args) {
    $fields = {
        name => {
            mandatory => 1, # not required
            unique    => 1, # not required
        },
        caffeine => {
            mandatory => 1, # not required
        },
    };
}

async method startup () {
    $last_id = await $api->storage->get('id');
}

async method next_id () {
    my $id = await $api->storage->incr('id');
    $last_id = $id;
    return $id;
}

async method request : RPC (%args) {
    $log->infof('GOT Machine Request: %s', \%args);

    my $storage = $api->storage;
    # Only accept PUT request
    if ( $args{type} eq 'PUT' or $args{type} eq 'POST') {
        my %body = $args{body}->%*;
        return {error => {text => 'Missing Argument. Must supply login, password, email', code => 400 } }
            if grep { ! exists $body{$_} } keys $fields->%*;

        my %unique_values;
        # should be converted to fmap instead of for
        for my $unique_field (grep { exists $fields->{$_}{unique}} keys $fields->%*) {
            my $value = await $storage->hash_get(join('.', 'unique', $unique_field), $body{$unique_field});
            return {error => {text => 'User already exists', code => 400 } } if $value;
            $unique_values{$unique_field} = $body{$unique_field};

        }
        $log->debugf('Unique values %s', \%unique_values);

        # Need to add more validation
        my %cleaned_body;
        @cleaned_body{keys $fields->%*} = @body{keys $fields->%*};

        my $id = await $self->next_id;

        await $storage->hash_set('machine', $id, encode_json_utf8(\%cleaned_body));
        await fmap_void(
            async sub {
                my $key = shift;
                await $storage->hash_set(join('.', 'unique', $key), $unique_values{$key}, 1);
            }, foreach => [keys %unique_values], concurrent => 4
        );
        $log->infof('added new machine with id: %d', $id);
        my $machine = {id => $id, record => \%cleaned_body};
        $new_machine_handler->emit($machine);
        return $machine;
    } else {
        return {error => {text => 'Wrong request METHOD please use PUT for this resource', code => 400 } };
    }
}

async method new_machine : Emitter() ($source){
    $new_machine_handler->each(sub {
        my $machine = shift;
        $source->emit($machine);
    });
}

1;
