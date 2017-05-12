#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use PkgForge::Job;

my $job = PkgForge::Job->new( bucket => 'lcfg',
                              report => 'foo@example.org, bar@example.com' );

isa_ok( $job, 'PkgForge::Job' );

is( $job->bucket, 'lcfg', 'job bucket is correct' );

is_deeply( $job->report,
           ['foo@example.org', 'bar@example.com' ],
           'report email list is correct' );

my $job2 = PkgForge::Job->new( bucket => 'lcfg',
                               report => ['foo@example.org',
                                          'bar@example.com'] );

is_deeply( [$job2->report_list],
           ['foo@example.org', 'bar@example.com' ],
           'report email list is correct' );
