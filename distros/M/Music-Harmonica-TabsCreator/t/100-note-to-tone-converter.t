use strict;
use warnings;
use Test2::V0;

use Music::Harmonica::TabsCreator::NoteToToneConverter;

my $converter = Music::Harmonica::TabsCreator::NoteToToneConverter->new;

is($converter->convert('C4'), [0]);
is($converter->convert('C5'), [12]);
is($converter->convert('C6'), [24]);
is($converter->convert('C3'), [-12]);
is($converter->convert('A4'), [9]);

is($converter->convert('Cb4'), [-1]);
is($converter->convert('C#4'), [1]);
is($converter->convert('C##4'), [2]);
is($converter->convert('C###4'), [3]);

sub convert {
  my $converter = Music::Harmonica::TabsCreator::NoteToToneConverter->new;
  return $converter->convert($_[0]);
}

is (convert('C > C < < A'), [12, 24, 9]);
is (convert("C C' A,"), [12, 24, 9]);

is (convert('B E A'), [23, 16, 21]);
is (convert('Kb B E A'), [22, 16, 21]);
is (convert('Kbb B E A'), [22, 15, 21]);
is (convert('Kbbb B E A'), [22, 15, 20]);
is (convert('KbBEA'), [22, 16, 21]);

is (convert('Kb B K B'), [22, 23]);
is (convert('KbBKB'), [22, 23]);

is (convert('Do do Fa F A'), [12, 12, 17, 17, 21]);
is (convert('DodoFaFA'), [12, 12, 17, 17, 21]);

is (convert('C # foo C'), [12, 'foo C']);
is (convert("C # foo\nD"), [12, "foo\n", 14]);

done_testing;
