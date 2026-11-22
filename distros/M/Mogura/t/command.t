use strict;
use warnings;
use Test::More;
use Errno qw(EIO);
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Time::HiRes qw(time);
use lib 'lib';
use Mogura::Scanner::Command;

my $command = Mogura::Scanner::Command->new;
my $dir = tempdir(CLEANUP => 1);

# Metacharacters are literal arguments, never shell input.
my $argument = '$(touch unsafe); `touch unsafe`';
my $result = $command->run([$^X, '-e', 'print $ARGV[0]', $argument], cwd => $dir);
is($result, $argument, 'Shell metacharacters stay literal');
ok(!-e "$dir/unsafe", 'No shell side effects');

{
    no warnings 'redefine';
    local *IO::Handle::blocking = sub { $! = EIO; return undef };
    my $marker = "$dir/launched";
    eval { $command->run(['/usr/bin/touch', $marker]) };
    like($@, qr/nonblocking/i, 'Pipe setup failure is reported');
    ok(!-e $marker, 'The command never starts without a nonblocking output pipe');
}

# Timeout and nonzero exit must remain observable failures.
my $start = time;
eval { $command->run([$^X, '-e', 'sleep 30'], timeout => 0.1) };
like($@, qr/timed out/, 'Command timeout is an error');
cmp_ok(time - $start, '<', 4, 'Timeout terminates and reaps the child');
eval { $command->run([$^X, '-e', 'exit 7']) };
like($@, qr/Command failed/, 'Nonzero exit is preserved as failure');

# Machine-readable stdout must not be contaminated by tool diagnostics.
my $output = "$dir/result.json.part";
$command->run(
    [$^X, '-e', 'print q({"matches":[]}); print STDERR q(warning)'],
    stdout => $output,
    log => "$dir/log"
);
is(path($output)->slurp, '{"matches":[]}', 'Artifact stdout is separate from stderr');
is(path("$dir/log")->slurp, 'warning', 'Warnings remain in scan log');

# Reaping the immediate child is insufficient if its descendants stay alive.
my $descendant_program = <<'PERL';
my $child = fork;
die $! unless defined $child;
if ($child == 0) {
    sleep 30;
    exit;
}
open my $pid_file, '>', $ARGV[0] or die $!;
print {$pid_file} $child;
close $pid_file;
sleep 30;
PERL
my $pid_file = "$dir/descendant.pid";
eval { $command->run([$^X, '-e', $descendant_program, $pid_file], timeout => 0.3); };
like($@, qr/timed out/, 'Timeout also handles a CLI with descendants');
my $child = path($pid_file)->slurp;
my $stat = -f "/proc/$child/stat" ? path("/proc/$child/stat")->slurp : '';
ok(!$stat || $stat =~ /\) Z /, 'CLI descendant is terminated (possibly awaiting init reap)');
done_testing;
