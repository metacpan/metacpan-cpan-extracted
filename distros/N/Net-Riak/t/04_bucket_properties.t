use lib 't/lib';
use Test::More;
use Test::Riak;
use Data::Dumper;

test_riak {
    my ($client, $bucket_name) = @_;

    my $bucket = $client->bucket($bucket_name);
    $bucket->allow_multiples(1);
    my $props = $bucket->get_properties;
    is ref($props), 'HASH', 'get properties returns a hash';

    is $bucket->allow_multiples, 1, 'allow multiples returns true';

    $bucket->n_val(3);
    is $bucket->n_val, 3, 'n_val is set to 3';
    $bucket->set_properties({allow_mult => 0, "n_val" => 2});

    is $bucket->allow_multiples, 0, "don't allow multiple anymore";
    is $bucket->n_val, 2, 'n_val is set to 2';
}


