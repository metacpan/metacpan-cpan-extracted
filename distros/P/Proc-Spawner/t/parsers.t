# The parsers' own tests (t/parser/*.pl): accepted or rejected as expected, and some whole trees.
# Also: Proc::ShellSubset::Small parses every test string as Proc::ShellSubset does with its options frozen, and,
# with dash and bash in PATH, every string the large grammar accepts is accepted by both shells' syntax checks.
use strict; use warnings; use Test::More;
my $shells = 2 == grep { my $s = $_; grep -x "$_/$s", split /:/, $ENV{PATH} // '' } qw(dash bash);
my @base = map "t/parser/$_", qw(shell-subset-tests.pl shell-subset-corpus-tests.pl);
for (['shell-subset-tests.pl'], ['shell-subset-corpus-tests.pl'], ['large-subset-tests.pl'], ['large-subset-tests.pl', '-s']) {
  my ($s, @a) = @$_;
  SKIP: { skip "t/parser/$s @a: needs dash and bash in PATH", 1 if @a && !$shells;
    my $out = qx{$^X t/parser/$s @a 2>&1};
    like $out, qr/^0 of [1-9][0-9]* unexpected$/m, "t/parser/$s @a" or diag $out } }
{ my $out = qx{$^X -Ilib t/parser/shellsubset-small-compare.pl lib lib @base 2>&1};
  like $out, qr/^0 of [1-9][0-9]* differ /m, 'Proc::ShellSubset::Small parses as Proc::ShellSubset' or diag $out }
SKIP: { skip 'the large grammar against the shells: needs dash and bash in PATH', 1 unless $shells;
  my $out = qx{$^X t/parser/large-subset-crosscheck.pl @base 2>&1};
  like $out, qr/^[1-9][0-9]* newly accepted \(0 of them rejected by a shell\)/m,
    'what only the large grammar accepts, both shells accept' or diag $out }
done_testing;
