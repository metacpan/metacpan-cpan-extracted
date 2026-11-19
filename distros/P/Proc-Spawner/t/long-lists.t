# X60 (ours; fixed post-0.12 by JH1, the user, 2026-11-15): a loop of the shell layer whose steps finish at once ran
# each next step from inside the one before, so 100 items or more made Perl warn "Deep recursion" (and memory grew with
# the items).  Now one helper, loop_async, runs such steps in a plain loop.  Each string here has 300 items, run in this
# process; any warning fails the test.  No program runs: the same on every platform.
use strict; use warnings;
use Test::More;
use Proc::ShellSubset::Large; use Proc::ShellSpawn;
my @warn; local $SIG{__WARN__} = sub { push @warn, @_ };
my $n = 300; my @i = 1 .. $n;
my %case = (
  'export, many names'                   => 'export ' . join(' ', map "a$_", @i),
  'settings before a command'            => join(' ', map "x$_=$_", @i) . ' true',
  'settings alone'                       => join(' ', map "y$_=$_", @i),
  'a double-quoted word, many expansions' => 'z=1; v="' . ('$z' x $n) . '"',
  'a here-document, many expansions'     => "z=1; : <<E\n" . ('$z ' x $n) . "\nE",
  'case, many patterns not matching'     => 'case zz in ' . join('|', map "a$_", @i) . ') false;; esac',
  'redirections, many'                   => ': ' . join(' ', map '2>&1', @i),
  'pattern parts, many'                  => 'case ' . ('a' x $n) . ' in ' . join('', map '"a"', @i) . ') : ;; *) false;; esac',
);
for my $name (sort keys %case) {
  @warn = ();
  my $st = Proc::ShellSpawn::run($case{$name});
  is $st, 0, "$name: status 0";
  is "@warn", '', "$name: no warning";
}
done_testing;
