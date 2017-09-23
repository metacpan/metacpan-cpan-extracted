#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Teamcity::Executor;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Data::Dumper;
use Teamcity::Executor;

if (
    $ENV{TEAMCITY_URL}      &&
    $ENV{TEAMCITY_USER}     &&
    $ENV{TEAMCITY_PASS}     &&
    $ENV{TEAMCITY_JOB_NAME}
) {
    plan tests => 2;
}
else {
    plan skip_all => 'Variables for TeamCity not set';
    return
}

my $loop = IO::Async::Loop->new;

my $tc = Teamcity::Executor->new(
    credentials => {
        url  => $ENV{TEAMCITY_URL},
        user => $ENV{TEAMCITY_USER},
        pass => $ENV{TEAMCITY_PASS},
    },
    loop => $loop,
);

$tc->register_polling_timer();

my ($f1) = $tc->run_teamcity_build(
    $ENV{TEAMCITY_JOB_NAME},
    { exit_code => 0 },
    'should_be_success',
);

my ($f2) = $tc->run_teamcity_build(
    $ENV{TEAMCITY_JOB_NAME},
    { exit_code => 1 },
    'should_be_failure',
);

my $res1 = $f1->then(
    sub {
        ok('build succeeded');
    },
    sub {
        fail('build failed');
    }
);

my $res2 = $f2->then(
    sub {
        fail('build succeeded');
    },
    sub {
        ok('build failed');
    }
);

my $f3 = Future->wait_all($f1, $f2);
my $res = $f3->then( sub { $loop->stop }, sub { $loop->stop } );

$loop->run();
