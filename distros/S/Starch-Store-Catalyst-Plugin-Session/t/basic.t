#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use Test::Starch;

my $tester = Test::Starch->new(
    store => {
        class  => '::Catalyst::Plugin::Session',
        store_class => '::File',
    },
);

$tester->test();

done_testing();
