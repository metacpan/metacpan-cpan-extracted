#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 4;
use Test::NoWarnings;

use Redis::JobQueue::Job;

# The names of object attributes
my @job_fields = qw(
    id
    queue
    job
    expire
    status
    meta_data
    workload
    result
    progress
    message
    created
    started
    updated
    completed
    failed
    );

my $pre_job = {
    id          => '4BE19672-C503-11E1-BF34-28791473A258',
    queue       => 'lovely_queue',
    job         => 'strong_job',
    expire      => 12*60*60,
    status      => 'created',
    workload    => \'Some stuff up to 512MB long',
    result      => \'JOB result comes here, up to 512MB long',
    };

my $job = Redis::JobQueue::Job->new( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

my @all_fields = sort @job_fields;

my @attributes = sort Redis::JobQueue::Job->job_attributes;

is "@attributes", "@all_fields", "all fields";

@attributes = sort $job->job_attributes;

is "@attributes", "@all_fields", "all fields";
