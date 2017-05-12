
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
  # old-sk00l awful expression maps are "always okay" -- other policies get'm
  q(map /stupid
  regex/, @list),

  # simple, everything on one line
  q(map { $_ } @list;),

  # simple, but with some newlines
  q(
map { $_ } @list;
),

  # multiple statements in block
  q(map { my $foo = $_;  $foo =~ s/butter/oleo/g; $foo } @list),

  # line breaks around block, but not in it
  # multiple statements in block
  q(map
  { my $foo = $_; $foo =~ s/butter/oleo/g; $foo }
  @list),
);

my @not_ok = (
  # line breaks in block
  q(map {
    my $foo = $_; $foo =~ s/butter/oleo/g; $foo
  } @list),
);

plan tests => @ok + @not_ok;

my $policy = 'Lax::ProhibitComplexMappings::LinesNotStatements';

for my $i (0 .. $#ok) {
  my $violation_count = pcritique($policy, \$ok[$i]);
  is($violation_count, 0, "nothing wrong with \@ok[$i]");
}

for my $i (0 .. $#not_ok) {
  my $violation_count = pcritique($policy, \$not_ok[$i]);
  is($violation_count, 1, "\@not_ok[$i] is no good");
}
