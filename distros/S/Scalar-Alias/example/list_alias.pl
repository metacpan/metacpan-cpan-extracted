#!perl -w

use strict;
use Scalar::Alias;

my $x = 10;

my alias($y, $z) = ($x, $x);

$x += 10;

print <<"EOT";
x = $x
y = $y
z = $z
EOT

