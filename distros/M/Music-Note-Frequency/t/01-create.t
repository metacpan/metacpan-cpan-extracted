# -*- perl -*-

# t/002-create.t - test that Music::Note::Frequency can create an object

use Test::Simple tests => 3;
use Music::Note::Frequency;

print "testing object creation\n";
my $note = Music::Note::Frequency->new({step=>'C',octave=>3,alter=>0});

ok($note->step eq 'C');
ok($note->octave == 3);
ok($note->alter == 0);

