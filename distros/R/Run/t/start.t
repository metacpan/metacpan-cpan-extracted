# Run::start, public since 0.07: a program other than argv[0], the specs {fd => M} and {close => 1},
# redirections given unnormalized; with fork and forkless (the wraparound, as on Win32, OS/2, VMS).
use strict; use warnings;
use Test::More;
use Run ();
use File::Temp qw(tempdir);
use POSIX ();
my $dir = tempdir(CLEANUP => 1);
my $perl = $^X;
sub lowest_free { my $d = POSIX::dup(0); POSIX::close($d); $d }   # (the next fd an open would get)
sub slurp { open my $f, '<', $_[0] or return ''; local $/; <$f> }
for my $forkless (0, 1) {
  local $Run::Forkless = $forkless;
  my $m = $forkless ? 'forkless' : 'fork';
  my @errs;
  # the program is $perl, argv[0] is "renamed" (perl ignores its argv[0])
  my $low = lowest_free();
  my $pid = Run::start(1, ['renamed', '-e', 'print "args: @ARGV\n"', 'a b', 'c'],
		       [1 => {filename => "$dir/o1", mode => '>'}], \@errs, $perl);
  ok $pid, "$m: start with a program other than argv[0]" or diag "@errs";
  waitpid $pid, 0 if $pid;
  is slurp("$dir/o1"), "args: a b c\n", "$m: its arguments, its output in the file";
  is lowest_free(), $low, "$m: the file start() opened is closed again";
  open my $keep, '>', "$dir/o2" or die;
  $pid = Run::start(1, [$perl, '-e', 'print STDERR "to err\n"; print "to out\n"; exit 3'],
		    [1 => {filehandle => $keep, pin => 1}, 2 => {fd => 1}], \@errs);
  waitpid $pid, 0 if $pid;
  is $? >> 8, 3, "$m: status";
  close $keep;
  is slurp("$dir/o2"), "to err\nto out\n", "$m: {fd => 1} as 2>&1";
  # (a shell: Perl itself reuses a closed fd 0 for a file it opens at startup)
  $pid = Run::start(1, ['/bin/sh', '-c', 'if (true 3<&0) 2>/dev/null; then echo open; else echo closed; fi'],
		    [0 => {close => 1}, 1 => {filename => "$dir/o3", mode => '>'}], \@errs);
  waitpid $pid, 0 if $pid;
  is slurp("$dir/o3"), "closed\n", "$m: {close => 1}";
  ok defined(my $d = POSIX::dup(0)), "$m: our fd 0 still open"; POSIX::close($d) if defined $d;
  $pid = Run::start(1, ['nosuch'], [], \@errs, "$dir/nosuch");
  ok !$pid && $! == POSIX::ENOENT(), "$m: a missing program: ENOENT" or diag "$! @errs";
}
done_testing;
