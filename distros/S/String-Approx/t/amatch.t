use String::Approx 'amatch';
use Test::More tests => 15;

chdir('t') or die "could not chdir to 't'";

require './util';

# test 1

open(WORDS, 'words') or die "could not find words";

my @words = <WORDS>;

ok(
   t(    
     [qw(
          appeal
          dispel
          erlangen
          hyperbola
          merlin
          parlance
          pearl
          perk
          superappeal
          superlative
       )],
     [amatch('perl', @words)]));

# test 2: same as 1 but no insertions allowed

ok(
   t(
     [qw(
          appeal
          dispel
          erlangen
          hyperbola
          merlin
          parlance
          perk
          superappeal
          superlative
       )],
     [amatch('perl', ['I0'], @words)]));

# test 3: same as 1 but no deletions allowed

ok(
   t(
     [qw(
          appeal
          hyperbola
          merlin
          parlance
          pearl
          perk
          superappeal
          superlative
       )],
     [amatch('perl', ['D0'], @words)]));

# test 4: same as 1 but no substitutions allowed

ok(
   t(
     [qw(
          dispel
          erlangen
          hyperbola
          merlin
          pearl
          perk
          superappeal
          superlative
       )],
     [amatch('perl', ['S0'], @words)]));
# test 5: 2-differences

ok(
   t(
     [qw(
          aberrant
          accelerate
          appeal
          dispel
          erlangen
          felicity
          gibberish
          hyperbola
          iterate
          legerdemain
          merlin
          mermaid
          oatmeal
          park
          parlance
          Pearl
          pearl
          perk
          petal
          superappeal
          superlative
          supple
          twirl
          zealous
       )],
     [amatch('perl', [2], @words)]));

# test 6: i(gnore case)

ok(
   t(
     [qw(
          appeal
          dispel
          erlangen
          hyperbola
          merlin
          parlance
          Pearl
          pearl
          perk
          superappeal
          superlative
       )],
     [amatch('perl', ['i'], @words)]));

# test 7: test for undefined input

{
  undef $_;
  local *SAVERR;
  open SAVERR, ">&STDERR";
  close STDERR;
  my $error;
  open STDERR, ">", \$error;
  ok(!defined amatch("foo"));
  ok($error =~ /what are you/);
  close STDERR;
  open STDERR, ">&SAVERR";
}

$_ = 'foo'; # anything defined so later tests do not fret

# test 8: test just for acceptance of a very long pattern

ok(!amatch("abcdefghij" x 10));

# test 9: test long pattern matching

$_ = 'xyz' x 10 . 'abc0defghijabc1defghij' . 'zyx' x 10;
ok(amatch('abcdefghij' x 2));

# test 10: test stingy matching.

ok(
   t(
     [qw(
          appeal
          dispel
          erlangen
          hyperbola
          merlin
          parlance
          pearl
          perk
          superappeal
          superlative
       )],
     [amatch('perl', ['?'], @words)]));

ok(!amatch("xyz", ""));
ok(amatch("", "xyz"));
ok(amatch("", ""));

ok(amatch("\x{100}d", "ab\x{100}cd"));

# that's it.
