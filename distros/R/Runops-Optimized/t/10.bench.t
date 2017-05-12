# Lame, but still interesting
use Test::More tests => 6;
use Time::HiRes qw(time);

my $plain = [];
my $runops = ["-Mblib", "-MRunops::Optimized"];

for $opts($plain, $runops, $plain, $plain, $runops, $runops) {
  my $type = @$opts ? "Runops::Optimized" : "Normal";
  my $start = time;
  open my $perl, "|-", $^X, @$opts;
  print $perl <<'EOF';
sub foo {
  for(1 .. 1e5) {
    ($_ % 2 ? $x : $y)++;
  }
}
foo() for 1 .. 50;
EOF
  close $perl;
  diag "$type: " . sprintf("%.4f", time - $start);
  pass "Tested $type";
}
