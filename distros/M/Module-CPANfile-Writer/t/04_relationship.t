use strict;
use warnings;

use Test::More;

use Module::CPANfile::Writer;

my $writer = Module::CPANfile::Writer->new(\<<'...');
requires 'A';
recommends 'A';
suggests 'B';
conflicts 'C';
...
$writer->add_prereq('A', '0.01');
$writer->add_prereq('A', '0.02', relationship => 'recommends');
$writer->add_prereq('B', '0.01', relationship => 'suggests');
$writer->add_prereq('C', '0.01', relationship => 'conflicts');
is $writer->src, <<'...';
requires 'A', '0.01';
recommends 'A', '0.02';
suggests 'B', '0.01';
conflicts 'C', '0.01';
...

done_testing;
