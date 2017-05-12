# -*- perl -*-

# t/002_create.t - check various note creation methods

use Test::Simple tests => 24;
use Music::Note;

my $note = Music::Note->new({step=>'C',octave=>3,alter=>0});

ok($note->step eq 'C');
ok($note->octave == 3);
ok($note->alter == 0);

$note = Music::Note->new("D#4","iso");

ok($note->step eq 'D');
ok($note->octave == 4);
ok($note->alter == 1);

$note = Music::Note->new("C#","isobase");

ok($note->step eq 'C');
ok($note->octave == 4);
ok($note->alter == 1);

$note = Music::Note->new("Af5","midi");

ok($note->step eq 'A');
ok($note->octave == 5);
ok($note->alter == -1);

$note = Music::Note->new("BB--","kern");

ok($note->step eq 'B');
ok($note->octave == 2);
ok($note->alter == -2);

$note = Music::Note->new(49,"midinum");

ok($note->step eq 'C');
ok($note->octave == 3);
ok($note->alter == 1);

$note = Music::Note->new("<pitch><step>E</step><octave>1</octave><alter>0</alter></pitch>","xml");

ok($note->step eq 'E');
ok($note->octave == 1);
ok($note->alter == 0);

$note = Music::Note->new("df2","pdl");

ok($note->step eq 'D');
ok($note->octave == 2);
ok($note->alter == -1);



