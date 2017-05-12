# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Utils qw(decode);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $str = "a\nb";
my $ret = decode($str);
is($ret, 'a\nb');
