# The Win32 code paths (0.07): the forkless code without fcntl (Win32API::File), through Run::start.  On Win32 itself
# (under Wine run it with Windows' own standard handles: cmd /c "perl t\win32.t > out.txt 2>&1"), and on Unix with
# $Run::AsWin32 set, where FD_CLOEXEC stands in for the handle's inheritance.  Children write into files.
use strict; use warnings;
use Test::More;
use Run (); use POSIX (); use File::Temp qw(tempdir);
my $real = $^O eq 'MSWin32';
($Run::AsWin32, $Run::Forkless) = (1, 1) unless $real;
note $real ? 'Win32' : 'Unix, with $Run::AsWin32: all but the Win32API::File calls';
my $dir = tempdir(CLEANUP => 1); my $perl = $^X;
sub script { my ($n, $code) = @_; open my $f, '>', "$dir/$n" or die; print $f $code; close $f; "$dir/$n" }
sub slurp { open my $f, '<', $_[0] or return ''; local $/; my $t = <$f>; close $f; $t =~ s/\r//g; $t }
my $ARGS = script('args.pl', 'print join("|", map "[$_]", @ARGV), "\n"; exit 3;');
my $ERR = script('err.pl', 'print STDERR "to err\n"; print "to out\n";');
my $IN = script('in.pl', 'print defined(sysread STDIN, my $b, 1) ? "open\n" : "closed\n";');
ok Run::forkless(), $real ? 'forkless by default' : 'forkless';
my $c = Run::dup_above(1, 20, '>'); ok $c && fileno($c) >= 20, 'dup_above without F_DUPFD';
is Run::is_cloexec(fileno $c), 1, 'its copy is not inherited (close-on-exec read through Win32API::File)';
Run::os_inherit(fileno $c, 1); is Run::is_cloexec(fileno $c), 0, 'made inheritable';
Run::set_cloexec(fileno $c); is Run::is_cloexec(fileno $c), 1, 'set_cloexec'; close $c;
my @errs;
my $pid = Run::start(1, ['renamed', $ARGS, 'c'], [1 => {filename => "$dir/o1", mode => '>'}], \@errs, $perl);
ok $pid, 'a program other than argv[0]' or diag "@errs"; waitpid $pid, 0 if $pid;
is $? >> 8, 3, 'its status'; is slurp("$dir/o1"), "[c]\n", 'its arguments, its output in the file';
open my $keep, '>', "$dir/o2" or die;
$pid = Run::start(1, [$perl, $ERR], [1 => {filehandle => $keep, pin => 1}, 2 => {fd => 1}], \@errs);
waitpid $pid, 0 if $pid; close $keep;
is slurp("$dir/o2"), "to err\nto out\n", 'a pinned file on fd 1, {fd => 1} as 2>&1';
# (on Unix a shell: Perl itself reuses a closed fd 0 for a file it opens at startup)
$pid = Run::start(1, $real ? [$perl, $IN] : ['/bin/sh', '-c', 'if (true 3<&0) 2>/dev/null; then echo open; else echo closed; fi'], [0 => {close => 1}, 1 => {filename => "$dir/o3", mode => '>'}], \@errs);
waitpid $pid, 0 if $pid; is slurp("$dir/o3"), "closed\n", '{close => 1} on fd 0';
ok defined(my $d = POSIX::dup(0)), 'our fd 0 put back'; POSIX::close($d) if defined $d;
$pid = Run::start(1, ['x'], [], \@errs, "$dir/nosuch.exe"); ok !$pid && $! == POSIX::ENOENT(), 'a missing program: ENOENT';
my @args = ('a b', 'q"x', 'c\\\\', '', 'tail\\');
TODO: { local $TODO = $real ? "Perl's system LIST does not quote arguments as the C runtime parses them back (a bug of Perl's)" : undef;
  $pid = Run::start(1, [$perl, $ARGS, @args], [1 => {filename => "$dir/o4", mode => '>'}], \@errs); waitpid $pid, 0 if $pid;
  is slurp("$dir/o4"), join('|', map "[$_]", @args) . "\n", 'argv arrives exactly' }
ok print(STDOUT ""), 'our stdout after the calls';
done_testing;
