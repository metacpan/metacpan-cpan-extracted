#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 56;

BEGIN {
    eval "use Test::Exception";     ## no critic
    plan skip_all => "because Test::Exception required for testing" if $@;
}

use Test::NoWarnings;

use Redis::JobQueue::Job;
use Redis::JobQueue::Util qw(
    format_message
);

# options for testing arguments: ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [] )

my $pre_job = {
    id          => '4BE19672-C503-11E1-BF34-28791473A258',
    queue       => 'lovely_queue',
    job         => 'strong_job',
    expire      => 12*60*60,
    status      => 'created',
    workload    => \'Some stuff up to 512MB long',
    result      => \'JOB result comes here, up to 512MB long',
    };

my $job = Redis::JobQueue::Job->new(
    id          => $pre_job->{id},
    queue       => $pre_job->{queue},
    job         => $pre_job->{job},
    expire      => $pre_job->{expire},
    status      => $pre_job->{status},
    workload    => $pre_job->{workload},
    result      => $pre_job->{result},
    );
isa_ok( $job, 'Redis::JobQueue::Job');

$job = Redis::JobQueue::Job->new( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

my $next_job = Redis::JobQueue::Job->new( $job );
isa_ok( $job, 'Redis::JobQueue::Job');

foreach my $expire ( ( -1, -3, "", "0.5", \"scalar", [], "something" ) )
{
    dies_ok { my $job = Redis::JobQueue::Job->new(
        id          => $pre_job->{id},
        queue       => $pre_job->{queue},
        job         => $pre_job->{job},
        expire      => $expire,
        status      => $pre_job->{status},
        workload    => $pre_job->{workload},
        result      => $pre_job->{result},
        ) } "expecting to die (expire = ".( $expire || "" ).")";
}

#foreach my $workload ( ( undef, [], \( "*" x ( Redis::JobQueue::Job::MAX_DATASIZE + 1 ) ) ) )
foreach my $workload ( ( undef ) )
{
    dies_ok { my $job = Redis::JobQueue::Job->new(
        id          => $pre_job->{id},
        queue       => $pre_job->{queue},
        job         => $pre_job->{job},
        expire      => $pre_job->{expire},
        status      => $pre_job->{status},
        workload    => $workload,
        result      => $pre_job->{result},
        ) } "expecting to die (workload = ".( substr( $workload || "", 0, 10 ) ).")";
}

#foreach my $result ( ( undef, [], \( "*" x ( Redis::JobQueue::Job::MAX_DATASIZE + 1 ) ) ) )
foreach my $result ( ( undef ) )
{
    dies_ok { my $job = Redis::JobQueue::Job->new(
        id          => $pre_job->{id},
        queue       => $pre_job->{queue},
        job         => $pre_job->{job},
        expire      => $pre_job->{expire},
        status      => $pre_job->{status},
        workload    => $pre_job->{workload},
        result      => $result,
        ) } "expecting to die (result = ".( substr( $result || "", 0, 10 ) ).")";
}

my $tmp_pre_job;

foreach my $field ( qw( id status ) )
{
    $tmp_pre_job = { %{$pre_job} };
    foreach my $val ( ( undef, \"scalar", [] ) )
    {
        $tmp_pre_job->{ $field } = $val;
        dies_ok { my $job = Redis::JobQueue::Job->new(
            $tmp_pre_job
            ) } "expecting to die ($field = ".( substr( $val || "", 0, 10 ) ).")";
    }
}

foreach my $field ( qw( queue job ) )
{
    $tmp_pre_job = { %{$pre_job} };
    foreach my $val ( ( \"scalar", [] ) )
    {
        $tmp_pre_job->{ $field } = $val;
        dies_ok { my $job = Redis::JobQueue::Job->new(
            $tmp_pre_job
            ) } "expecting to die ($field = ".( substr( $val || "", 0, 10 ) ).")";
    }
}

$tmp_pre_job = { %{$pre_job} };
foreach my $val ( ( undef, -1, -3, "", 9999999999999999, \"scalar", [] ) )
{
    $tmp_pre_job->{progress} = $val;
    dies_ok { my $job = Redis::JobQueue::Job->new(
        $tmp_pre_job
        ) } format_message( 'expecting to die (progress = %s)', $val );
}

$tmp_pre_job = { %{$pre_job} };
foreach my $val ( ( \"scalar", [] ) )
{
    $tmp_pre_job->{message} = $val;
    dies_ok { my $job = Redis::JobQueue::Job->new(
        $tmp_pre_job
        ) } format_message( 'expecting to die (message = %s)', $val );
}

foreach my $field ( qw( created updated completed failed ) )
{
    $tmp_pre_job = { %{$pre_job} };
    foreach my $val ( ( -1, -3, "", \"scalar", [], "something" ) )
    {
        $tmp_pre_job->{ $field } = $val;
        dies_ok { my $job = Redis::JobQueue::Job->new(
            $tmp_pre_job
            ) } "expecting to die ($field = ".( substr( $val || "", 0, 10 ) ).")";
    }
}
