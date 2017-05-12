# -*- perl -*-

# t/004_format.t - check output formats

use Test::Simple tests => 16;
use Music::Note;

my $note = Music::Note->new("D#4");

ok($note->format eq 'D#4');
ok($note->format("iso") eq 'D#4');
ok($note->format("midi") eq 'Ds4');
ok($note->format("midinum") == 63);
ok($note->format("isobase") eq 'D#');
ok($note->format("kern") eq 'd#');
ok($note->format("pdl") eq 'ds4');
ok($note->format("xml") eq '<pitch><step>D</step><octave>4</octave><alter>1</alter></pitch>');

$note = Music::Note->new("Eb2");

ok($note->format eq 'Eb2');
ok($note->format("iso") eq 'Eb2');
ok($note->format("midi") eq 'Ef2');
ok($note->format("midinum") == 39);
ok($note->format("isobase") eq 'Eb');
ok($note->format("kern") eq 'EE-');
ok($note->format("pdl") eq 'ef2');
ok($note->format("xml") eq '<pitch><step>E</step><octave>2</octave><alter>-1</alter></pitch>');
