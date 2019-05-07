#!perl
use Test::More;

use_ok 'Music::ScaleNote';

my $msn = Music::ScaleNote->new(
    scale_note => 'C',
    scale_name => 'pminor',
#    verbose    => 1,
);
isa_ok $msn, 'Music::ScaleNote';

my $x;

my $format = 'midinum';
$x = $msn->get_offset(
    note_name   => 60,
    note_format => $format,
    offset      => 1,
);
isa_ok $x, 'Music::Note';
is $x->format($format), 63, 'get_offset';

$format = 'ISO';
is $x->format($format), 'D#4', 'get_offset';

$x = $msn->get_offset(
    note_name   => 'D#4',
    note_format => $format,
    offset      => -1,
);
isa_ok $x, 'Music::Note';
is $x->format($format), 'C4', 'get_offset';

$format = 'midinum';
is $x->format($format), 60, 'get_offset';

done_testing();
