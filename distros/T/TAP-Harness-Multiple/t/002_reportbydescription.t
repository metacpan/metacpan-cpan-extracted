# -*- perl -*-
use strict;
use warnings;
use Test::More qw( no_plan );
use TAP::Harness::ReportByDescription;
use IO::CaptureOutput qw( capture );

use_ok( 'TAP::Parser::Aggregator' );

my ($aggregator, $harness);
my ($stdout, $stderr);
my @tests;

##### Ordinary use of TAP::Harness #####

@tests = (
    't/testlib/alpha.t',
    't/testlib/beta.t',
);

$aggregator = TAP::Parser::Aggregator->new;
ok( defined($aggregator),
    "TAP::Parser::Aggregator::new() returned defined value" );
isa_ok( $aggregator, 'TAP::Parser::Aggregator' );
$aggregator->start();

$harness = TAP::Harness->new();
ok( $harness,
    "TAP::Harness->new() returned true value" );
isa_ok( $harness, 'TAP::Harness' );

capture(
    sub { $harness->aggregate_tests($aggregator, @tests); },
    \$stdout,
    \$stderr,
);
like( $stdout,
    qr/t\/testlib\/alpha\.t/s,
    "alpha.t reported by filename",
);
like( $stdout,
    qr/t\/testlib\/beta\.t/s,
    "beta.t reported by filename",
);
$aggregator->stop();

###### Use of Test::Harness::ReportByDescription #####

# For Test::Harness::ReportByDescription we only need to demonstrate
# that what appears on STDOUT is the description rather than the filename.

@tests = (
    [
        't/testlib/alpha.t',
        'simple__t/testlib/alpha.t',
    ],
    [
        't/testlib/beta.t',
        'more__t/testlib/beta.t',
    ],
);
$aggregator = TAP::Parser::Aggregator->new;
ok( defined($aggregator),
    "TAP::Parser::Aggregator::new() returned defined value" );
isa_ok( $aggregator, 'TAP::Parser::Aggregator' );
$aggregator->start();

$harness = TAP::Harness::ReportByDescription->new();
ok( $harness,
    "TAP::Harness::ReportByDescription->new() returned true value" );
isa_ok( $harness, 'TAP::Harness::ReportByDescription' );
can_ok( $harness, qw|
    summary
    make_scheduler
    jobs
    finish_parser 
| );

capture(
    sub { $harness->aggregate_tests($aggregator, @tests); },
    \$stdout,
    \$stderr,
);
like( $stdout,
    qr/simple__t\/testlib\/alpha\.t/s,
    "alpha.t reported by description rather than filename",
);
like( $stdout,
    qr/more__t\/testlib\/beta\.t/s,
    "beta.t reported by description rather than filename",
);
$aggregator->stop();

##### Test $ENV{TEST_JOBS} > 1 #####

$aggregator = TAP::Parser::Aggregator->new;
ok( defined($aggregator),
    "TAP::Parser::Aggregator::new() returned defined value" );
isa_ok( $aggregator, 'TAP::Parser::Aggregator' );
$aggregator->start();

$harness = TAP::Harness::ReportByDescription->new( {
    jobs        => 4,
} );
ok( $harness,
    "TAP::Harness::ReportByDescription->new() returned true value" );
isa_ok( $harness, 'TAP::Harness::ReportByDescription' );
can_ok( $harness, qw|
    summary
    make_scheduler
    jobs
    finish_parser 
| );

capture(
    sub { $harness->aggregate_tests($aggregator, @tests); },
    \$stdout,
    \$stderr,
);
like( $stdout,
    qr/simple__t\/testlib\/alpha\.t/s,
    "alpha.t reported by description rather than filename",
);
like( $stdout,
    qr/more__t\/testlib\/beta\.t/s,
    "beta.t reported by description rather than filename",
);
$aggregator->stop();

