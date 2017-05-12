#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 26;
use Test::NoWarnings;

BEGIN { use_ok 'Redis::JobQueue::Job', qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
    ) }

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

my @job_methods = qw(
    new
    modified_attributes
    clear_modified
    job_attributes
    elapsed
    );

foreach my $method ( @job_fields, @job_methods )
{
    can_ok( 'Redis::JobQueue::Job', $method );
}

my $val;
ok( $val = STATUS_CREATED(),    "import OK: $val" );
ok( $val = STATUS_WORKING(),    "import OK: $val" );
ok( $val = STATUS_COMPLETED(),  "import OK: $val" );
ok( $val = STATUS_FAILED(),     "import OK: $val" );
