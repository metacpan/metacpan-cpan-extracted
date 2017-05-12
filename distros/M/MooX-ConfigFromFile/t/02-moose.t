#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    eval "use Moose;";
    $@ and plan skip_all => "Moose test requires Moose being installed";
}

our $OO = "Moose";
$ENV{WHICH_MOODEL} = "Moose";

eval "do 't/testerr.pm'";
eval "do 't/testlib.pm'";
eval "use MooX::Cmd 0.012; do 't/testmxcmd.pm'";
eval "{package MooX::ConfigFromFile::Test::Availability::Of::MooX::Options; use $OO; use MooX::Options 4.001; }; do 't/testmxopt.pm'";

done_testing;
