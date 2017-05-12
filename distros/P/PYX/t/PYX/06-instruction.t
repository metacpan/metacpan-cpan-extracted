# Pragmas.
use strict;
use warnings;

# Modules.
use PYX qw(instruction);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $data = 'target data';
my $ret = instruction($data);
is($ret, '?target data');

# Test.
$data = "target data\ndata";
$ret = instruction($data);
is($ret, '?target data\ndata');

# Test.
$ret = instruction('target', 'data');
is($ret, '?target data', 'Get PYX code for instruction with target and data.');
