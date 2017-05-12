
use strict;

use Test::More tests => 1;
use Sed;

my ($a, $b);

# test 3
$a = "Hello, world";
$b = sed { tr/a-z/A-Z/ } $a;

isnt($a, $b);
