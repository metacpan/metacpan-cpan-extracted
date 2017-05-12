
use Test::More tests => 1;

use Set::IntSpan;
use Set::IntSpan::Partition;

my @input = (
  Set::IntSpan->new('1-10,20,31-40'),
  Set::IntSpan->new('7'),
  Set::IntSpan->new('7-8'),
  Set::IntSpan->new('1-50'),
  Set::IntSpan->new('1-50'),
  Set::IntSpan->new('5,6-39'),
);

my @output = intspan_partition @input;
my @sorted = sort { $a cmp $b } map "$_", @output;
my $expect = 
[
 '1-4,40',
 '11-19,21-30',
 '41-50',
 '5-6,9-10,20,31-39',
 '7',
 '8'
];

is_deeply(\@sorted, $expect, "Simple sample");
