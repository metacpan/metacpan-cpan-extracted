#!/usr/bin/env perl
use strictures 2;

use Test2::V0;
use Test2::Require::EnvVar 'AMAZON_DYNAMODB_LOCAL_TESTS';
use Test2::Require::Module 'Starch::Plugin::TimeoutStore';
use Test::Starch;

my $tester = Test::Starch->new(
    plugins => ['::TimeoutStore'],
    store => {
        class  => '::Amazon::DynamoDB',
        table => "sessions-$$-$<-" . time(),
        timeout => 1,
        connect_on_create => 0,
        ddb => {
            implementation => 'Amazon::DynamoDB::LWP',
            version        => '20120810',
            access_key     => 'access_key',
            secret_key     => 'secret_key',
            host  => 'localhost',
            port  => 8000,
            scope => 'us-east-1/dynamodb/aws4_request',
        },
    },
);

$tester->new_manager->store->create_table();

$tester->test();

done_testing();
