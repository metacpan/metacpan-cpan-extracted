use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Path::Tiny;

use_ok('Stor');

my @storages = (
    Path::Tiny->tempdir(TEMPLATE => 'storagea_XXXX'),
    Path::Tiny->tempdir(TEMPLATE => 'storagea_XXXX'),
    Path::Tiny->tempdir(TEMPLATE => 'storageb_XXXX'),
    Path::Tiny->tempdir(TEMPLATE => 'storageb_XXXX'),
);

my $storage_pairs = [
    [ $storages[0]->stringify(), $storages[1]->stringify(), ],
    [ $storages[2]->stringify(), $storages[3]->stringify(), ],
];

subtest 'all storages writable' => sub {
    my $stor = Stor->new(
        storage_pairs => $storage_pairs,
        get_from_hcp  => 0,
    );

    my $pairs = $stor->get_storages_free_space;
    is(scalar @$pairs, 2);
    ok($pairs->[0] > 0) or diag $pairs->[0];
    ok($pairs->[1] > 0) or diag $pairs->[1];

    done_testing(3);
};

subtest 'storageb read only' => sub {
    my $stor = Stor->new(
        storage_pairs        => $storage_pairs,
        get_from_hcp         => 0,
        writable_pairs_regex => 'storagea.*',
    );

    my $pairs = $stor->get_storages_free_space;
    is(scalar @$pairs, 2);
    ok($pairs->[0] > 0) or diag $pairs->[0];
    is($pairs->[1], 0);

    done_testing(3);
};
