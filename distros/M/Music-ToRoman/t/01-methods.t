#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ToRoman';

my $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
);
isa_ok $mtr, 'Music::ToRoman';

my $roman = $mtr->parse('Am');
is $roman, 'i', 'i';
$roman = $mtr->parse('Bo');
is $roman, 'iio', 'iio';
$roman = $mtr->parse('CM');
is $roman, 'III', 'III';
$roman = $mtr->parse('Cm9/G');
is $roman, 'iii9/VII', 'iii9/VII';
$roman = $mtr->parse('Em7');
is $roman, 'v7', 'v7';
$roman = $mtr->parse('A+');
is $roman, 'I+', 'I+';
$roman = $mtr->parse('BbM');
is $roman, 'bII', 'bII';
$roman = $mtr->parse('Bm add4');
is $roman, 'ii add4', 'ii add4';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
    chords     => 0,
);
$roman = $mtr->parse('A');
is $roman, 'i', 'i';
$roman = $mtr->parse('B');
is $roman, 'ii', 'ii';
$roman = $mtr->parse('C');
is $roman, 'III', 'III';

done_testing();
