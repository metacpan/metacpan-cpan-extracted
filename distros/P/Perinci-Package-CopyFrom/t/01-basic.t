#!perl

use strict;
use warnings;
use Test::More 0.98;

package Perinci::Package::CopyFrom::Test::Copy;
use Perinci::Package::CopyFrom;
copy_from {exclude=>[qw/$SCALAR1 @ARRAY1 %HASH2 func1 func2/]},
    'Perinci::Package::CopyFrom::Test';

package main;
no warnings 'once';

subtest "basics" => sub {
    is_deeply( \%Perinci::Package::CopyFrom::Test::Copy::SPEC, {
        '$SCALAR2' => {v=>1.1, summary=>'SCALAR2'},
        '@ARRAY2'  => {v=>1.1, summary=>'ARRAY2'},
        '%HASH1'   => {v=>1.1, summary=>'HASH1'},
        'func3'    => {v=>1.1, summary=>'func3'},
    }) or diag explain \%Perinci::Package::CopyFrom::Test::Copy::SPEC;
};

DONE_TESTING:
done_testing;
