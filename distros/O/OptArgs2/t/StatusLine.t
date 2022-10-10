#!perl
use strict;
use warnings;
use OptArgs2::StatusLine 'RS', '$line';
use Test2::V0;
use Test::Output 'stdout_from';

my $prefix1 = 'StatusLine.t: ' . RS;
my $prefix2 = 'new:' . RS;
my $prefix3 = 'newer:' . RS;
my $i       = 0;
my $old     = undef;

is $line, undef, 'initially undefined';

is stdout_from( sub { $line = $i; } ), "$prefix1$i\n", 'assignment ' . $line;
$i++;
is stdout_from( sub { $line = $i; } ), "$prefix1$i\n", 'reassignment ' . $line;
$old = $line;
$i++;
is stdout_from( sub { $line .= $i; } ), "$old$i\n", 'concatenation ' . $line;

# Just hide this from test output
stdout_from( sub { $line = 'A' } );

is stdout_from( sub { $line = \'new:' } ), "${prefix2}A\n",
  'new prefix scalar ref ' . $line;

is stdout_from( sub { $line = $i; } ), "$prefix2$i\n", 'assignment ' . $line;
$i++;
is stdout_from( sub { $line = $i; } ), "$prefix2$i\n", 'reassignment ' . $line;
$old = $line;
$i++;
is stdout_from( sub { $line .= $i; } ), "$old$i\n", 'concatenation ' . $line;

is stdout_from( sub { $line = $prefix3 . 'B' } ), "${prefix3}B\n",
  'newer prefix RS ' . $line;

is stdout_from( sub { $line = $i; } ), "$prefix3$i\n", 'assignment ' . $line;
$i++;
is stdout_from( sub { $line = $i; } ), "$prefix3$i\n", 'reassignment ' . $line;
$old = $line;
$i++;
is stdout_from( sub { $line .= $i; } ), "$old$i\n", 'concatenation ' . $line;

done_testing();
