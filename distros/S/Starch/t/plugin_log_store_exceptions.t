#!/usr/bin/env perl
use 5.008001;
use strictures 2;

use Test2::V0;
use Test::Starch;
use Log::Any::Test;
use Log::Any qw($log);
use Starch;

Test::Starch->new(
    plugins => ['::LogStoreExceptions'],
)->test();
$log->clear();

{
    package Starch::Store::Test::LogStoreExceptions;
    use Moo;
    with 'Starch::Store';
    sub set { die "SET FAIL" }
    sub get { die "GET FAIL" }
    sub remove { die "REMOVE FAIL" }
}

my $log_starch = Starch->new(
    plugins => ['::LogStoreExceptions'],
    store => { class=>'::Test::LogStoreExceptions' },
);
my $log_store = $log_starch->store();

my $die_starch = Starch->new(
    store => { class=>'::Test::LogStoreExceptions' },
);
my $die_store = $die_starch->store();

foreach my $method (qw( set get remove )) {

    $log_store->$method( 1234, [] );
    my $uc_method = uc( $method );

    $log->category_contains_ok(
        'Starch::Store::Test::LogStoreExceptions',
        qr{$uc_method FAIL},
        "$method exception logged",
    );
    $log->empty_ok();

    like(
        dies { $die_store->$method( 1234, [] ) },
        qr{$uc_method FAIL},
        "$method exception thrown",
    );

}

done_testing;
