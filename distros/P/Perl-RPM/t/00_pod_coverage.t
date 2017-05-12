#!/usr/bin/perl -w

use Test::More;

eval "use Test::Pod::Coverage 1.00";

plan skip_all =>
    "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan tests => 5;

pod_coverage_ok(RPM => { also_private => [ qr/bootstrap_/ ] }, 'RPM');
pod_coverage_ok(RPM::Constants => { also_private => [ 'constant' ] },
                'RPM::Constants');
pod_coverage_ok(RPM::Database => 'RPM::Database');
pod_coverage_ok(RPM::Error => 'RPM::Error');
pod_coverage_ok(RPM::Header => { also_private => [ qw(dump write) ] },
                'RPM::Header');

exit;
