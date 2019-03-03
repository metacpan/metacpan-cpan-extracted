#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use Test::Starch;

my $db_file = 'test.db';
unlink( $db_file ) if -f $db_file;

my $tester = Test::Starch->new(
    store => {
        class  => '::DBIx::Connector',
        connector => [
            'dbi:SQLite:dbname=test.db',
            '',
            '',
            { RaiseError => 1 },
        ],
    },
);

my $store = $tester->new_manager->store();

my $table = $store->table();
my $key_column = $store->key_column();
my $data_column = $store->data_column();
my $expiration_column = $store->expiration_column();

$store->connector->run(sub{
    $_->do(qq[
        CREATE TABLE $table (
            $key_column TEXT NOT NULL PRIMARY KEY,
            $data_column TEXT NOT NULL,
            $expiration_column INTEGER NOT NULL
        )
    ]);
});

$tester->test();

done_testing();
