#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Teamcity::Executor;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Data::Dumper;

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
    poll_interval => 3,
);

$tc->register_polling_timer();

my $artifact_name = 'artifact_name';
my $artifact_content = 'artifact_content';

my ($f1) = $tc->run_teamcity_build(
    $ENV{TEAMCITY_JOB_NAME},
    {
        exit_code => 0,
        seconds_to_sleep => 1,
        artifact_content => $artifact_content,
        artifact_name => $artifact_name,
    },
    'build-with-artifact'
);


my $res1 = $f1->then(
    sub {
        my ($result) = @_;
        ok('build succeeded');

        my $returned_content;
        $returned_content = $tc->get_artifact_content(
            $result, $artifact_name
        );

        is($returned_content, $artifact_content, 'artifact content ok');

        $loop->stop()

    },
    sub {
        fail('build failed');
        $loop->stop()
    }
);

$loop->run();
