#! perl
# new_pipeline: simple commands are spawned; an element that is not (and,
# or, chain, a nested pipeline) runs in this process, which keeps its pipe
# ends open until the element's last command has ended.  Run with
# redirections applied in the kid (fork) and in the parent ($Run::Forkless).
use strict; use warnings;
use Test::More;
use POSIX ();
use File::Temp qw(tempdir);
use Run ':NEW';

my $dir = tempdir(CLEANUP => 1);
my $out = "$dir/out";
sub slurp { open my $f, '<', $_[0] or return; local $/; scalar <$f> }
sub perl { new_system($^X, '-e', @_) }
sub to { new_redir([1 => {filename => $_[0], mode => '>'}], $_[1]) }
sub fds { opendir my $d, '/proc/self/fd' or return 'n/a'; join ' ', sort { $a <=> $b } grep /^\d/, readdir $d }
# The last element: prefixes and counts its input lines.
my $C = perl('while (<STDIN>) { $n++; print "C:$_" } print "C saw ", $n // 0, " lines\n"');
# Runs the pipeline with its output in $out; dies after 20 s (a hang).
sub run_p {
  my ($p, $d) = @_;
  local $SIG{ALRM} = sub { die "timeout\n" };
  alarm 20;
  my $ok = eval { to($out, new_pipeline(@$p))->run($d //= {errs => []}) };
  alarm 0;
  $@ and return "died: $@";
  $ok;
}

for my $wrap (0, 1) {
  local $Run::Forkless = $wrap;
  my $m = $wrap ? 'forkless' : 'fork';
  my $fds = fds();
  my %d = (errs => []);

  # { A || { S >/dev/null; B; } } | C.  While S runs, no kid holds the
  # write end; only this process keeps C from seeing EOF before B.
  my $flag = "$dir/b-ran"; unlink $flag;
  my $S = new_redir([1 => {filename => '/dev/null', mode => '>'}], perl('sleep 1'));
  ok run_p([new_or(perl('print "a\n"; exit 1'), new_chain($S, perl('print "b\n"'))), $C], \%d),
    "$m: { A || { S; B; } } | C succeeds";
  is slurp($out), "C:a\nC:b\nC saw 2 lines\n", "$m: ... C reads A's and B's output as one stream";
  is $d{result}, 0, "$m: ... status 0";

  ok run_p([new_or(perl('print "a\n"'), perl("open my \$f, '>', '$flag'")), $C]), "$m: { A || B } | C, A succeeds";
  is slurp($out), "C:a\nC saw 1 lines\n", "$m: ... only A's output";
  ok !-e $flag, "$m: ... B never started";

  # Status: that of the last element.
  ok !run_p([perl('exit 0'), perl('exit 3')], do { %d = (errs => []); \%d }), "$m: true | exit 3 fails";
  is $d{result}, 3 << 8, "$m: ... status 3";
  ok run_p([perl('exit 3'), perl('exit 0')]), "$m: exit 3 | true succeeds";
  ok !run_p([perl('exit 0'), new_or(perl('exit 1'), perl('exit 4'))], do { %d = (errs => []); \%d }),
    "$m: true | { false || exit 4; } fails";
  is $d{result}, 4 << 8, "$m: ... status 4, from the element run here";

  # Input side: this process must close the producer's write end, or B never sees EOF.
  ok run_p([perl('print "$_\n" for 1 .. 3'),
	    new_or(new_system('sh', '-c', 'read l; echo "A:$l"; exit 1'), perl('print "B:$_" while <STDIN>'))]),
    "$m: P | { A || B; }";
  is slurp($out), "A:1\nB:2\nB:3\n", "$m: ... A reads one line, B the rest, then EOF";

  # Middle element, and more data than a pipe holds (C must already run).
  ok run_p([perl('print "$_\n" for qw(b a b)'), new_chain(new_system('sort')), $C]), "$m: P | { sort; } | C";
  is slurp($out), "C:a\nC:b\nC:b\nC saw 3 lines\n", "$m: ... sorted";
  ok run_p([new_chain(perl('print "x" x 1_000_000')), perl('local $/; print length <STDIN>')]),
    "$m: { 1 MB; } | C does not deadlock";
  is slurp($out), "1000000", "$m: ... all of it";

  # Order: outer redirections, then the pipe, then the element's own.
  ok run_p([new_redir([2 => {filename => '>&1'}], new_or(perl('print STDERR "e\n"; exit 1'), perl('print "o\n"'))), $C]),
    "$m: { A || B; } 2>&1 | C";
  is slurp($out), "C:e\nC:o\nC saw 2 lines\n", "$m: ... stderr joins the pipe";

  # SIGPIPE: nobody but C may hold the read end.
  ok run_p([new_chain(perl('$| = 1; print "y\n" while 1')), perl('print scalar <STDIN>')]),
    "$m: { yes; } | head -1 ends";
  is slurp($out), "y\n", "$m: ... one line";

  # Elements that do not start.
  ok run_p([new_system('no-such-prog-xyz'), $C], do { %d = (errs => []); \%d }), "$m: missing | C";
  is slurp($out), "C saw 0 lines\n", "$m: ... C sees EOF";
  like "@{$d{errs}}", qr/no-such-prog-xyz/, "$m: ... the error is reported";
  ok !run_p([perl('1'), new_system('no-such-prog-xyz')], do { %d = (errs => []); \%d }), "$m: true | missing fails";
  is $d{result}, -1, "$m: ... result -1";

  # Two elements that are not simple commands.
  %d = (errs => []);
  my $two = run_p([new_chain(perl('print "1\n"'), perl('print "2\n"')), new_chain($C)], \%d);
  if ($wrap) {
    ok !$two, "$m: { a; b; } | { c; } refused without fork";
    like "@{$d{errs}}", qr/only one element/, "$m: ... with a message";
  } else {
    ok $two, "$m: { a; b; } | { c; } (first one forked)";
    is slurp($out), "C:1\nC:2\nC saw 2 lines\n", "$m: ... output";
    ok !run_p([new_chain(perl('exit 0')), new_or(perl('exit 1'), perl('exit 6'))], do { %d = (errs => []); \%d }),
      "$m: { true; } | { false || exit 6; }";
    is $d{result}, 6 << 8, "$m: ... status 6";
    ok run_p([new_chain(perl('$| = 1; print "y\n" while 1')), new_chain(perl('print scalar <STDIN>'))]),
      "$m: { yes; } | { head -1; } ends";
  }

  # A pipeline inside a pipeline, and one element alone.
  ok run_p([new_pipeline(perl('print "n\n"'), perl('print "m$_" while <STDIN>')), $C]), "$m: (P | Q) | C";
  is slurp($out), "C:mn\nC saw 1 lines\n", "$m: ... output";
  ok run_p([perl('print "alone\n"')]), "$m: one element";
  is slurp($out), "alone\n", "$m: ... output";

  is fds(), $fds, "$m: no fd left open in this process";

  # Nothing ran: result is -1, not left over from before.
  my $refused = new_pipeline(new_chain(perl('1')), new_chain(perl('1')));
  %d = (errs => []);
  perl('exit 0')->run(\%d);
  my $ok = new_pipeline(perl('1'), $refused)->run(\%d);
  if ($wrap) {
    ok !$ok, "$m: true | (refused pipeline) fails";
    is $d{result}, -1, "$m: ... result -1";
  } else {
    ok $ok, "$m: true | ({ a; } | { b; }) runs";
  }
}

# A die in an element must not escape a forked copy, nor leave kids unreaped.
my $escaped = "$dir/escaped"; unlink $escaped;
my $me = $$;
my %d = (errs => []);
my $bad = new_chain(new_env('NOT_A_HASH', perl('1')));	# dies: not a hash
eval { new_pipeline($bad, new_chain(perl('print <STDIN>')))->run(\%d) };
if ($$ != $me) { open my $f, '>', $escaped; POSIX::_exit(0) }
ok !-e $escaped, "fork: a die in a forked copy stays there";
like "@{$d{errs}}", qr/HASH/, "fork: ... and comes back as a message";
eval { new_pipeline(perl('sleep 0'), $bad)->run({errs => []}) };
like $@, qr/HASH/, "a die in the element run here propagates";
is waitpid(-1, POSIX::WNOHANG()), -1, "... after the kids were reaped";

# Messages from a forked copy reach the caller's errs.
%d = (errs => []);
new_pipeline(new_chain(new_system('no-such-prog-xyz')), new_chain(perl('1')))->run(\%d);
like "@{$d{errs}}", qr/exec `no-such-prog-xyz'/, "fork: errors of a forked copy are collected";

done_testing;
