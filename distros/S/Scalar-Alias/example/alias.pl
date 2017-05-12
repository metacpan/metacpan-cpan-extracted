#!perl -w

use strict;
use Scalar::Alias;

my $x = 10;

my alias $y = $x;

$x += 10;

print <<"EOT";
x = $x
y = $y
EOT

