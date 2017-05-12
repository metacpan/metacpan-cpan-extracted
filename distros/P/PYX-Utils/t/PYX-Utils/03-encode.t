# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Utils qw(encode);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $str = 'a\nb';
my $ret = encode($str);
is($ret, "a\nb");
