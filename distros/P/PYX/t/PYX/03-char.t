# Pragmas.
use strict;
use warnings;

# Modules.
use PYX qw(char);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $char = 'char';
my $ret = char($char);
is($ret, '-char');

# Test.
$char = "char\nchar";
$ret = char($char);
is($ret, '-char\nchar');
