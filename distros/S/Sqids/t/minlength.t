use strict;
use Test::More 0.98;
use Test::Exception;

use_ok 'Sqids';

my $defaults =
    Class::Tiny->get_all_attribute_defaults_for('Sqids');
my $default_alphabet_length = length $defaults->{alphabet};

subtest 'simple' => sub {
    my $sqids = Sqids->new({ min_length => $default_alphabet_length });
    my @numbers = (1, 2, 3);
    my $id = '86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM';

    is $sqids->encode(@numbers), $id, 'Encodes to correct value';
    is_deeply [ $sqids->decode($id) ], \@numbers, 'Decodes to correct value';
};

subtest 'incremental' => sub {
    my $numbers = [1, 2, 3];

    my %map = (
         6 => '86Rf07',
         7 => '86Rf07x',
         8 => '86Rf07xd',
         9 => '86Rf07xd4',
         10 => '86Rf07xd4z',
         11 => '86Rf07xd4zB',
         12 => '86Rf07xd4zBm',
         13 => '86Rf07xd4zBmi',
         $default_alphabet_length + 0 =>
             '86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM',
         $default_alphabet_length + 1 =>
             '86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMy',
         $default_alphabet_length + 2 =>
             '86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf',
         $default_alphabet_length + 3 =>
             '86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf1'
    );

    foreach my $min_length (sort keys %map) {
        my $id = $map{$min_length};
        my $sqids = Sqids->new( min_length => $min_length );
        is $sqids->encode($numbers), $id;
        is length $sqids->encode($numbers), $min_length;
        is_deeply [ $sqids->decode($id) ], $numbers;
     }
};

subtest 'incremental numbers' => sub {
    my $sqids = Sqids->new({ min_length => $default_alphabet_length });

    my %ids = (
        SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu => [0, 0],
        n3qafPOLKdfHpuNw3M61r95svbeJGk7aAEgYn4WlSjXURmF8IDqZBy0CT2VxQc => [0, 1],
        tryFJbWcFMiYPg8sASm51uIV93GXTnvRzyfLleh06CpodJD42B7OraKtkQNxUZ => [0, 2],
        eg6ql0A3XmvPoCzMlB6DraNGcWSIy5VR8iYup2Qk4tjZFKe1hbwfgHdUTsnLqE => [0, 3],
        rSCFlp0rB2inEljaRdxKt7FkIbODSf8wYgTsZM1HL9JzN35cyoqueUvVWCm4hX => [0, 4],
        sR8xjC8WQkOwo74PnglH1YFdTI0eaf56RGVSitzbjuZ3shNUXBrqLxEJyAmKv2 => [0, 5],
        uY2MYFqCLpgx5XQcjdtZK286AwWV7IBGEfuS9yTmbJvkzoUPeYRHr4iDs3naN0 => [0, 6],
        '74dID7X28VLQhBlnGmjZrec5wTA1fqpWtK4YkaoEIM9SRNiC3gUJH0OFvsPDdy' => [0, 7],
        '30WXpesPhgKiEI5RHTY7xbB1GnytJvXOl2p0AcUjdF6waZDo9Qk8VLzMuWrqCS' => [0, 8],
        moxr3HqLAK0GsTND6jowfZz3SUx7cQ8aC54Pl1RbIvFXmEJuBMYVeW9yrdOtin => [0, 9],
    );

    foreach (keys %ids) {
        is $sqids->encode($ids{$_}), $_;
        is_deeply [ $sqids->decode($_) ], $ids{$_};
    }
};

subtest 'min lengths' => sub {
    foreach my $min_length (0, 1, 5, 10, $default_alphabet_length) {
        foreach my $numbers (
            [0],
            [0, 0, 0, 0, 0],
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            [100, 200, 300],
            [1_000, 2_000, 3_000],
            [1_000_000],
        ) {
            my $sqids = Sqids->new({ min_length => $min_length });
            my $id = $sqids->encode($numbers);
            cmp_ok(length $id, '>=', $min_length);
            is_deeply [ $sqids->decode($id) ], $numbers;
        }
    }
};

# for those langs that don't support `u8`
subtest 'out-of-range invalid min length' => sub {
    my $min_length_limit = 255;
    my $min_length_error = "Minimum length has to be between 0 and $min_length_limit";

    throws_ok {
        Sqids->new({ min_length => -1 });
    } qr/$min_length_error/;

    throws_ok {
        Sqids->new({ min_length => $min_length_limit + 1 })
    } qr/$min_length_error/;
};

done_testing;
