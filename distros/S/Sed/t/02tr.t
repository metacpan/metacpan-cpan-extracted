use strict;

use Test::More tests => 1;
use Sed;

my ($a, $b, $c);

$a = "The quick brown fox jumped over the lazy dog.";
$b = sed { tr/aeiou/AEIOU/ } $a;
$c = sed { tr/AEIOU/aeiou/ } $b;

is($a, $c);
