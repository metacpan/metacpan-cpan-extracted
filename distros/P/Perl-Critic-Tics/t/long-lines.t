
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my $snippet = '$xy; '; # 5 chars long

my @ok = (
  $snippet, # just a short line
  join("\n", ($snippet) x 20), # a lot of short lines
  join("\n", ($snippet x 20), ($snippet) x 100), # ~1% of lines over base
);

my @not_ok = (
  join(" ", ($snippet) x 20), # 100% of lines are over base
  [ 5, join("\n", (($snippet x 20) x 5), ($snippet) x 100) ], # ~5% over base

  # one line is over the hard limit, but there aren't enough violations to
  # complain about the lines that are (base < length < hard)
  [ 1, join("\n", ($snippet x 20), ($snippet x 40), ($snippet) x 200) ],
);

plan tests => @ok + @not_ok + 1;

my $policy = 'Tics::ProhibitLongLines';

for my $i (0 .. $#ok) {
  my $violation_count = pcritique($policy, \$ok[$i]);
  is($violation_count, 0, "nothing wrong with \$ok[$i]");
}

for my $i (0 .. $#not_ok) {
  my $count = 1;
  my $code = $not_ok[$i];
  ($count, $code) = @$code if ref $code;
  my $viol = pcritique($policy, \$code);
  is($viol, $count, "\$not_ok[$i] is no good ($viol violations)");
}

my $data_long = <<'END_DATA';
my $x = 'short';
my $y = 'short, too';

__DATA__
END_DATA

$data_long .= ('x' x 200);

my $violation_count = pcritique($policy, \$data_long);
is($violation_count, 0, "nothing wrong with long lines in __DATA__");
