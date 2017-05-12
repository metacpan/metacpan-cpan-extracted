use warnings;
use strict;

$^W++; # for some reason use warnings doesn't cut it

use Test::More;
eval "use Test::Warn";
plan skip_all => "Test::Warn required for testing reentry" if $@;

use Parse::RecDescent;


my $g1 = <<'EOG';
  {
    use warnings;
    use strict;

    my @seq;
  }

  genome  : base(s)
              { $return = \@seq }

  base    : A | C | G | T

  A       : /a/ { push @seq, $item[0] }
  C       : /c/ { push @seq, $item[0] }
  G       : /g/ { push @seq, $item[0] }
  T       : /t/ { push @seq, $item[0] }
EOG


my $g2 = <<'EOG';
  {
    use warnings;
    use strict;

    my @seq;
  }

  genome  : ( A | C | G | T )(s)
              { $return = \@seq }

  A       : /a/ { push @seq, $item[0] }
  C       : /c/ { push @seq, $item[0] }
  G       : /g/ { push @seq, $item[0] }
  T       : /t/ { push @seq, $item[0] }
EOG


my @sequences = (qw/aatgcttgc cctggattcg ctggaagtc ctgXc/);
plan tests => @sequences * 4;

for my $to_sequence (@sequences) {

  my ($p1, $p2);

  warnings_are (sub {
    $p1 = Parse::RecDescent->new ($g1);
  }, [], 'no warnings emitted during grammar1 parsing');

  warnings_are (sub {
    $p2 = Parse::RecDescent->new ($g2);
  }, [], 'no warnings emitted during grammar2 parsing');

  warnings_are (sub {
    is_deeply (
      $p1->genome ($to_sequence),
      $p2->genome ($to_sequence),
      'grammars produce same result'
    );
  }, [], 'no warnings emitted during grammar execution');
}
