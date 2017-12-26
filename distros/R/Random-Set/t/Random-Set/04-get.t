use strict;
use warnings;

use Random::Set;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Random::Set->new(
         'set' => [
                 [0.5, 'foo'],
                 [0.5, 'bar'],
         ],
);
my $ret = $obj->get;
like($ret, qr{foo|bar}, "Get 'foo' or 'bar'.");
