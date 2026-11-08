#! perl
# Redirections must not depend on which fds were open when Run started,
# and must leave the parent's fd table as it was: the same fds open, on the
# same files, with the same close-on-exec flags.  Each scenario runs against
# many starting fd tables, with redirections applied in the kid (fork) and in
# the parent around the spawn ($Run::Wraparound).
# Linux only: the checks read /proc/self/fd and /proc/self/fdinfo.
use strict; use warnings;
use POSIX ();
use Fcntl qw(F_SETFD FD_CLOEXEC);
use File::Temp qw(tempdir);
use Run ":NEW";
$| = 1;

unless (-d "/proc/self/fdinfo") { print "1..0 # skip needs /proc/self/fdinfo\n"; exit }

my $dir = tempdir(CLEANUP => 1);
my ($A, $B) = ("$dir/a", "$dir/b");
sub slurp { open my $f, '<', $_[0] or return ''; local $/; scalar <$f> }

# The kid writes "fdN " to every fd N in @ARGV that is open, "fdN:closed " to fd 1 otherwise.
my $KID = q{for my $n (@ARGV) { if (open my $h, ">&=", $n) { syswrite $h, "fd$n " } else { syswrite STDOUT, "fd$n:closed " } }};
sub kid { new_system($^X, '-e', $KID, @_) }
sub f   { +{filename => $_[0]} }

my @scenarios = (
  [ 'nested 11 then 13>&11' =>
    sub { new_redir({11 => f(">$A")}, new_redir({13 => f('>&11')}, kid(11, 13))) },
    sub { slurp($A) eq 'fd11 fd13 ' } ],
  [ '1>a 2>&1 (hash)' =>
    sub { new_redir({1 => f(">$A"), 2 => f('>&1')}, kid(1, 2)) },
    sub { slurp($A) eq 'fd1 fd2 ' } ],
  [ '2>&1 1>a (array order kept)' =>
    sub { new_redir({1 => f(">$B")}, new_redir([2 => f('>&1'), 1 => f(">$A")], kid(1, 2))) },
    sub { slurp($A) eq 'fd1 ' and slurp($B) eq 'fd2 ' } ],
  [ '5>&- closes 5 in the kid only' =>
    sub { new_redir([1 => f(">$A"), 5 => f('>&-')], kid(5)) },
    sub { slurp($A) eq 'fd5:closed ' } ],
  [ '4>a 3>b, files land on targets' =>
    sub { new_redir([4 => f(">$A"), 3 => f(">$B")], kid(3, 4)) },
    sub { slurp($A) eq 'fd4 ' and slurp($B) eq 'fd3 ' } ],
  [ 'pipe under 5>a' =>
    sub { new_readpipe(new_redir({5 => f(">$A")}, kid(1, 5))) },
    sub { $_[0] eq 'fd1 ' and slurp($A) eq 'fd5 ' } ],
  [ '12>&1 (filehandle)' =>
    sub { new_redir({1 => f(">$A")}, new_redir({12 => {filehandle => \*STDOUT}}, kid(12))) },
    sub { slurp($A) eq 'fd12 ' } ],
);

# Starting tables: which fds 3..15 are open before the run.  Even fds are raw
# and inheritable (as if inherited from our parent); odd fds are owned by
# Perl handles and close-on-exec, as Perl opens them.
my @tables = ([], [3], [5], [3..10], [3..12], [3..15], [4, 11, 13],
              map { my $m = $_; [grep { $m >> ($_ - 3) & 1 } 3..15] } 0x5a5, 0xa5a, 0x1234, 0x0f0f);

sub snapshot {			# fd => "target cloexec" for 0..40
  my %s;
  for my $n (0..40) {
    defined(my $l = readlink "/proc/self/fd/$n") or next;
    open my $i, '<', "/proc/self/fdinfo/$n" or next;
    my ($fl) = map /^flags:\s*(\d+)/ ? oct $1 : (), <$i>;
    $s{$n} = "$l " . ($fl & 02000000 ? 'cloexec' : 'inherit');
  }
  join ', ', map "$_=$s{$_}", sort { $a <=> $b } keys %s;
}

my @modes = split /,/, $ENV{FDTABLE_MODES} // "0,1";
my $total = @modes * @scenarios * @tables;
print "1..$total\n";
my $t = 0;
for my $wrap (@modes) {
  local $Run::Wraparound = $wrap;
  for my $table (@tables) {
    for my $sc (@scenarios) {
      my ($name, $build, $check) = @$sc;
      unlink $A, $B;
      my $pid = fork // die "fork: $!";
      if (!$pid) {		# a fresh process per case, so cases cannot interact
        my @hold;
        for my $n (@$table) {
          my $fd = POSIX::open('/dev/null', POSIX::O_RDONLY());
          POSIX::dup2($fd, $n) or die; POSIX::close($fd) if $fd != $n;
          if ($n % 2) { local $^F = 2; open my $h, '<&=', $n or die; push @hold, $h }
        }
        my $label = ($wrap ? 'wraparound' : 'fork') . " [@$table] $name";
        $SIG{ALRM} = sub { print "not ok - $label\n# hung (a pipe end left open?)\n"; POSIX::_exit(0) };
        alarm 5;
        my $before = snapshot();
        my $out = $build->()->run({errs => \my @errs});
        my $after = snapshot();
        my @why;
        push @why, "kid result wrong (a=[" . slurp($A) . "] b=[" . slurp($B) . "] out=[" . ($out // 'undef') . "] errs=[@errs])"
          unless defined $out and $check->($out);
        push @why, "parent fds changed:\n#  before $before\n#  after  $after" if $before ne $after;
        print STDOUT @why ? "not ok" : "ok", " - $label\n", map "# $_\n", @why;
        POSIX::_exit(0);
      }
      waitpid $pid, 0;
      $t++;
    }
  }
}
