use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Perlmazing qw(flatten);

my $object = "dummy";
$object = \$object;
bless $object;

my @flat = flatten [ 1, [ 2, 3 ], [[[4]]], 5, [6], [[7]], [[8,9]], {10 => [11, 12], 13 => {14 => 15}}, $object];

my $joined = join ', ', @flat;
my $matches = $joined =~ /^1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, main=REF\(.*?\)$/;

is $matches, 1, 'flatten worked correctly with nested arrayrefs, hashrefs, scalars and objects';
