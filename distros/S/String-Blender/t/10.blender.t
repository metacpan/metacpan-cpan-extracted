#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 8;

use String::Blender;

can_ok('String::Blender', 'new');

my $blender = String::Blender->new(
    vocabs => [
        ['doi:#1/pn', 'aAsZ.1$.\^'],
        ['я�¿', 'ミュニティーの一員'],
    ],
    min_length       => 10,
    max_length       => 30,
    min_elements     => 3,
    max_elements     => 5,
    max_tries_factor => 4,
);

isa_ok($blender, 'String::Blender');
can_ok($blender, 'blend');
can_ok($blender, 'load_vocabs');

$blender->quantity(2000);

ok(2000 == $blender->quantity, 'setting quantity');

ok(
    $blender->vocab_files( [
        't/blender/voc1.txt',
        [ 't/blender/voc2.txt', 't/blender/voc3.txt', ],
        't/blender/voc4.txt',
    ] ),
   'loading vocabs from files'
);

is_deeply(
    $blender->vocabs,
    [
        [qw/web net host site list archive core base switch/],
        [qw/area city club dominion empire field land valley world
            hood region spot location district/],
        [qw/candy honey muffin sugar sweet yammy/],
    ],
    'adequate vocabs loaded'
);

my $r_quantity = scalar($blender->blend);

ok(2000 == $r_quantity, 'sufficient blend() result');
diag "Resulting quantity = $r_quantity";
