#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 65;
use Test::NoWarnings;

use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
    );

my $pre_job = {
    id          => '4BE19672-C503-11E1-BF34-28791473A258',
    queue       => 'lovely_queue',
    job         => 'strong_job',
    expire      => 12*60*60,
    status      => 'created',
    workload    => \'Some stuff up to 512MB long',
    result      => \'JOB result comes here, up to 512MB long',
    progress    => 0.1,
    message     => 'Any message',
    created     => time,
    started     => time,
    updated     => time,
    completed   => time,
    failed      => time,
    };

my $job = Redis::JobQueue::Job->new( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

#foreach my $field ( keys %{$pre_job} )
foreach my $field ( $job->job_attributes )
{
    if ( $field =~ /^workload|^result/ )
    {
        is ${$job->$field}, ${$pre_job->{ $field }}, "accessor return a valid value (".${$job->$field}.")";
    }
    elsif ( $field =~ /^meta_data/ )
    {
        is_deeply $job->$field, {}, 'accessor return a valid value (empty hash)';
        next;
    }
    else
    {
#        is $job->$field, $pre_job->{ $field }, "accessor return a valid value (".$job->$field.")";
        ok $job->$field, "accessor return a valid value (".$field.")";
    }

    if ( $field =~ /^workload|^result/ )
    {
        $job->$field( scalar reverse ${$job->$field} );
        is scalar( reverse( ${$job->$field} ) ), ${$pre_job->{ $field }}, "accessor return a valid value (".${$job->$field}.")";
        $job->$field( \( scalar reverse ${$job->$field} ) );
        is ${$job->$field}, ${$pre_job->{ $field }}, "accessor return a valid value (".${$job->$field}.")";
    }
    elsif ( $field =~ /^expire|^created|^started|^updated|^completed|^failed/ )
    {
        $job->$field( $job->$field + 1 );
#        is $job->$field - 1, $pre_job->{ $field }, "accessor return a valid value (".$job->$field.")";
        ok $job->$field, "accessor return a valid value (".$field.")";
    }
    elsif ( $field =~ /^progress/ )
    {
        $job->$field( $job->$field + 0.01 );
        is $job->$field - 0.01, $pre_job->{ $field }, "accessor return a valid value (".$job->$field.")";
    }
    else
    {
       $job->$field( scalar reverse $job->$field // 'Any stuff' );
        is scalar( reverse( $job->$field ) ), $pre_job->{ $field }, "accessor return a valid value (".$job->$field.")";
    }
}

# elapsed

$pre_job = {
    id          => '4BE19672-C503-11E1-BF34-28791473A258',
    queue       => 'lovely_queue',
    job         => 'strong_job',
    expire      => 12*60*60,
    workload    => \'Some stuff up to 512MB long',
    result      => \'JOB result comes here, up to 512MB long',
    };

$job = Redis::JobQueue::Job->new( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');

ok $job->created,                   'created is set';
ok $job->updated,                   'updated is set';
is $job->started, 0,                'started not set';
is $job->completed, 0,              'completed not set';
is $job->failed, 0,                 'failed not set';
is $job->elapsed, undef,            'elapsed not set';

$job->status( STATUS_WORKING );
my $started = $job->started;
ok $started,                        'started is set';
is $job->completed, 0,              'completed not set';
is $job->failed, 0,                 'failed not set';
ok defined( $job->elapsed ),        'elapsed is set';

sleep 1;
$job->status( STATUS_WORKING );
is $job->started, $started,         'started set only once';

foreach my $status ( ( STATUS_COMPLETED, STATUS_FAILED ) )
{
    $job = Redis::JobQueue::Job->new( $pre_job );
    isa_ok( $job, 'Redis::JobQueue::Job');

    $job->status( $status );
    is $job->started, 0,            'started not set';
    if ( $status eq STATUS_COMPLETED )
    {
        ok $job->completed,             'completed is set';
        ok !$job->failed,               'failed not set';
    }
    elsif ( $status eq STATUS_FAILED )
    {
        ok !$job->completed,            'completed not set';
        ok $job->failed,                'failed is set';
    }
    is $job->elapsed, undef,        'elapsed not set';
}

foreach my $status ( ( STATUS_COMPLETED, STATUS_FAILED ) )
{
    $job = Redis::JobQueue::Job->new( $pre_job );
    isa_ok( $job, 'Redis::JobQueue::Job');

    $job->status( STATUS_WORKING );
    $job->status( $status );
    ok $job->started,               'started is set';
    if ( $status eq STATUS_COMPLETED )
    {
        ok $job->completed,             'completed is set';
        ok !$job->failed,               'failed not set';
    }
    elsif ( $status eq STATUS_FAILED )
    {
        ok !$job->completed,            'completed not set';
        ok $job->failed,                'failed is set';
    }
    ok defined( $job->elapsed ),    'elapsed is set';
}
