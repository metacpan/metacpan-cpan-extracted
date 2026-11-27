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
{ # X30: a command's line is looked up among the text's newlines, which are found once (it was counted from the start of
  # the text for each command).  600 lines: one-line commands, commands that span two lines, blank and comment lines,
  # here-documents; then the same with an alias whose value moves the rest of each line.
  require Proc::ShellSubset::Large;
  my ($t, $ln, @want) = ('', 1);
  for my $i (1 .. 150) {
    for (["echo \$LINENO $i\n", 1], ["e \\\n  two lines\n", 2], ["\n# a comment\n", 0], ["cat <<E\nbody $i\nE\n", 3]) {
      my ($piece, $n) = @$_; push @want, $ln if $n; $t .= $piece; $ln += $piece =~ tr/\n// } }
  for my $o ([], [aliases => { e => 'echo  a   longer    text' }]) {
    my $r = Proc::ShellSubset::Large::parse($t, @$o);
    my @got = ref $r eq 'ARRAY' ? map $_->[0][0]{line}, @$r : ($r->{error});
    is_deeply \@got, \@want, 'the line of each command of a long text' . (@$o ? ', with an alias expanded' : '') . ' (X30)' } }
{ # X56: after exec no grammar takes a builtin's name (V7): the shells look only for a program there, and find none
  require Proc::ShellSubset; require Proc::ShellSubset::Small; require Proc::ShellSubset::Large;
  my @o = map +($_ => 1), qw(if while for case read assign param_ops);
  my %p = (base => sub { Proc::ShellSubset::parse($_[0], @o) }, Small => \&Proc::ShellSubset::Small::parse, Large => \&Proc::ShellSubset::Large::parse);
  for my $g (sort keys %p) {
    my @bad = grep { my $r = $p{$g}->($_); !(ref $r eq 'HASH' && $r->{error} eq "unsupported 'exec' form") }
      'exec umask', 'exec command -v ls', 'exec type ls', 'exec read x', 'exec set -e', 'exec exec ls', 'exec wait';
    push @bad, grep ref $p{$g}->($_) ne 'ARRAY', 'exec ls -l', 'exec echo hi', 'exec test -d /';
    ok !@bad, "$g: exec with a builtin's name refused, with a program's accepted (X56)" or diag join "\n", @bad } }
done_testing;
