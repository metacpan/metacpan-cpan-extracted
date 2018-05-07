#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;

our $OO = "Moo";

unshift @INC, "." unless grep { "." eq $_ } @INC;

ok(do 't/testerr.pm', "do 't/testerr.pm'");
ok(do 't/testlib.pm', "do 't/testlib.pm'");
$@ and diag($@);
eval "use MooX::Cmd 0.012; 1" and ok(do 't/testmxcmd.pm', "do 't/testmxcmd.pm'");
eval "{package MooX::ConfigFromFile::Test::Availability::Of::MooX::Options; use Moo; use MooX::Options 4.001; }; 1"
  and ok(do 't/testmxopt.pm', "do 't/testmxopt.pm'");

done_testing;
