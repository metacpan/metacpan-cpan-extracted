use strict;
use warnings;

use Test::More;

use Module::CPANfile::Writer;

my $writer = Module::CPANfile::Writer->new(\<<'...');
requires 'A1';
requires 'A2', '0.01';
requires 'A3' => '0.01';
requires 'A4', 0.01;

requires('B1');
requires('B2', '0.01');
requires('B3' => '0.01');

requires "C1";
requires q{C2};
requires qq{C3};

requires 'D1', '0.01', dist => 'FOO/Foo-0.01.tar.gz';
requires 'D2', dist => 'FOO/Foo-0.01.tar.gz';

recommends 'E1';
suggests 'E2';
conflicts 'E3';

requires $FOO;
requires 'F', $BAR;
requires'G',,'0.01';
requires 'H', '0.01';
requires 'H', '0.01';
requires 'I1', '0.01';
requires 'I2', '0.01';
requires 'I3' ,,  '0.01';
requires
     'J',
    '0.01';
requires K => '0.01';
...
$writer->add_prereq('A1', '0.02');
$writer->add_prereq('A2', '0.02');
$writer->add_prereq('A3', '0.02');
$writer->add_prereq('A4', '0.02');
$writer->add_prereq('B1', '0.02');
$writer->add_prereq('B2', '0.02');
$writer->add_prereq('B3', '0.02');
$writer->add_prereq('C1', '0.02');
$writer->add_prereq('C2', '0.02');
$writer->add_prereq('C3', '0.02');
$writer->add_prereq('D1', '0.02');
$writer->add_prereq('D2', '0.02');
$writer->add_prereq('E1', '0.02', relationship => 'recommends');
$writer->add_prereq('E2', '0.02', relationship => 'suggests');
$writer->add_prereq('E3', '0.02', relationship => 'conflicts');
$writer->add_prereq('F', '0.02');
$writer->add_prereq('G', '0.02');
$writer->add_prereq('H', '0.02');
$writer->add_prereq('I1', undef);
$writer->add_prereq('I2', '0');
$writer->add_prereq('I3', undef);
$writer->add_prereq('J', '0.02');
$writer->add_prereq('K', '0.02');
is $writer->src, <<'...';
requires 'A1', '0.02';
requires 'A2', '0.02';
requires 'A3' => '0.02';
requires 'A4', '0.02';

requires('B1', '0.02');
requires('B2', '0.02');
requires('B3' => '0.02');

requires "C1", '0.02';
requires q{C2}, '0.02';
requires qq{C3}, '0.02';

requires 'D1', '0.02', dist => 'FOO/Foo-0.01.tar.gz';
requires 'D2', '0.02', dist => 'FOO/Foo-0.01.tar.gz';

recommends 'E1', '0.02';
suggests 'E2', '0.02';
conflicts 'E3', '0.02';

requires $FOO;
requires 'F', '0.02';
requires'G',,'0.02';
requires 'H', '0.02';
requires 'H', '0.02';
requires 'I1';
requires 'I2';
requires 'I3';
requires
     'J',
    '0.02';
requires K => '0.02';
...

done_testing;

