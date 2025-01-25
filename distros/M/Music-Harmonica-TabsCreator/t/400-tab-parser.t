use strict;
use warnings;
use Test2::V0;

use Music::Harmonica::TabsCreator::TabParser;

sub parse {
  my $parser = Music::Harmonica::TabsCreator::TabParser->new({
    1 => 'C4', -1 => 'D4', 2 => 'E4', -2 => 'G4', 3 => 'G4', -3 => 'A4', 4 => 'B4', -4 => 'C5',
    "1'" => 'Cb4', "-1'" => 'Db4', "2'" => 'Eb4', "-2'" => 'Gb4'});
  return $parser->parse($_[0]);
}

is (parse('1 -1 2 -2 3'), [qw(C4 D4 E4 G4 G4)]);
is (parse("1 1' -1 -1'"), [qw(C4 Cb4 D4 Db4)]);

done_testing;
