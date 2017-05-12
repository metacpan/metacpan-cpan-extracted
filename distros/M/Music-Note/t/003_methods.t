# -*- perl -*-

# t/003_methods.t - check various manipulation methods

use Test::Simple tests => 12;
use Music::Note;

my $note = Music::Note->new({step=>'C',octave=>3,alter=>0});
$note->transpose(-1);

ok($note->step eq 'B');
ok($note->octave == 2);
ok($note->alter == 0);

$note->transpose(14);

ok($note->step eq 'C');
ok($note->octave == 4);
ok($note->alter == 1);

$note->en_eq('f');

ok($note->step eq 'D');
ok($note->octave == 4);
ok($note->alter == -1);

$note->alter(1);

ok($note->step eq 'D');
ok($note->octave == 4);
ok($note->alter == 1);
