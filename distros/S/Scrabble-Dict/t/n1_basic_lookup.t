use Scrabble::Dict qw/scrabble_define/;

print "1..1\n";
print "ok 1 - successful online lookup\n" if
  scrabble_define('quixotry') =~ /quixotic action or thought/i;

