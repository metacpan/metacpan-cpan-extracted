#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More;
plan "no_plan";

BEGIN {
    eval "use Test::Exception";                 ## no critic
    plan skip_all => "because Test::Exception required for testing" if $@;
}

use Test::NoWarnings;

use List::MoreUtils qw(
    firstidx
    );
use Redis::JobQueue::Job;

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

my @attributes = Redis::JobQueue::Job->job_attributes;
ok( ( firstidx { $_ eq 'meta_data' } Redis::JobQueue::Job->job_attributes ) != -1, 'metadata attribute exists' );

# Functionality
is_deeply $job->meta_data, {}, 'empty hash by default';
ok !exists( $job->meta_data->{ fake } ), 'key does not exist';
is $job->meta_data( 'fake' ), undef, 'key does not exist';
ok $job->{__modified}->{meta_data}, 'meta_data changed';
$job->clear_modified( 'meta_data' );
ok !$job->{__modified}->{meta_data}, 'meta_data unchanged';
is $job->meta_data( 'fake', '123' ), undef, 'when set to no return';
ok $job->{__modified_meta_data}->{fake}, 'meta_data changed';
ok exists( $job->meta_data->{ fake } ), 'key exists';
is $job->meta_data( 'fake' ), '123', 'correct value';
is_deeply $job->meta_data, { fake => '123' }, 'correct hash';
is $job->meta_data( { foo => '123', bar => '234' } ), undef, 'when set to no return';
is_deeply $job->meta_data, { foo => '123', bar => '234' }, 'correct hash';

my @arr = $job->job_attributes;

# assignment metadata in the constructor
$pre_job->{meta_data} = {
        'foo'   => 12,
        'bar'   => [ 13, 14, 15 ],
        'other' => { a => 'b', c => 'd' },
        };
$job = Redis::JobQueue::Job->new( $pre_job );
isa_ok( $job, 'Redis::JobQueue::Job');
is_deeply $job->meta_data, $pre_job->{meta_data}, 'correct metadata';

# assignment metadata from previous job
$job->meta_data( 'foo', 16 );
my $next_job = Redis::JobQueue::Job->new( $job );
isa_ok( $next_job, 'Redis::JobQueue::Job');
is_deeply $next_job->meta_data, $job->meta_data, 'correct metadata';

# bad metadata field name
foreach my $field ( @attributes )
{
    dies_ok { $job->meta_data( $field, 'something' ) } 'expecting to die - bad metadata field name';
    dies_ok { $job->meta_data( { $field => 'something' } ) } 'expecting to die - bad metadata field name';
}
