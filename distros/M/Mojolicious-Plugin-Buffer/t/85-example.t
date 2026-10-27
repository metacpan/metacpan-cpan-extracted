use strict;
use warnings;

use Test::More;
use Config;
use File::Basename qw(dirname);
use File::Spec ();
use File::Temp ();
use IO::Socket::INET;
use Mojo::UserAgent;
use POSIX qw(WNOHANG);
use Time::HiRes ();

# Smoke test for the runnable example in examples/hypnotoad: start it under
# hypnotoad on an unused port and check that the cached route misses once and
# then hits, so the documented deployment really works.

plan skip_all => 'hypnotoad requires a UNIX-like system' if $^O eq 'MSWin32';

my $hypnotoad;
for my $dir (dirname(File::Spec->rel2abs($^X)), split(/\Q$Config{path_sep}\E/, $ENV{PATH} // '')) {
	next unless defined($dir) && length($dir);
	my $candidate = File::Spec->catfile($dir, 'hypnotoad');
	if (-f $candidate) {
		$hypnotoad = $candidate;
		last;
	}
}
plan skip_all => 'hypnotoad is not installed' unless $hypnotoad;

eval { require CHI; 1 }
	or plan skip_all => 'the example needs CHI';

my $root    = dirname(dirname(File::Spec->rel2abs($0)));
my $example = File::Spec->catdir($root, 'examples', 'hypnotoad');
my $script  = File::Spec->catfile($example, 'script', 'my_app');
plan skip_all => 'the runnable example is missing' unless -f $script;

my $tmp       = File::Temp->newdir('mpb-example-XXXXXX', TMPDIR => 1);
my $cache_dir = File::Spec->catdir("$tmp", 'cache');
my $lock_dir  = File::Spec->catdir("$tmp", 'locks');
my $pid_file  = File::Spec->catfile("$tmp", 'hypnotoad.pid');
my $log       = File::Spec->catfile("$tmp", 'hypnotoad.log');
mkdir($cache_dir) or die "Cannot create $cache_dir: $!";
mkdir($lock_dir)  or die "Cannot create $lock_dir: $!";

my $probe = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Listen    => 1,
	ReuseAddr => 1,
) or plan skip_all => "Cannot bind a local port: $!";
my $port = $probe->sockport;
close($probe);

my ($server_pid, $server_group) = (0, 0);

sub stop_server {
	return unless $server_pid;
	my $pid = $server_pid;
	$server_pid = 0;
	return unless $server_group;

	kill('TERM', -$pid);
	my $deadline = Time::HiRes::time() + 3;
	while (Time::HiRes::time() < $deadline) {
		last unless kill(0, -$pid);
		Time::HiRes::sleep(0.1);
	}
	kill('KILL', -$pid) if kill(0, -$pid);
	waitpid($pid, WNOHANG);

	return;
}

END { stop_server() }

$server_pid = fork;
defined($server_pid) or die "Cannot fork: $!";

if (!$server_pid) {
	open(STDIN, '<', File::Spec->devnull) or POSIX::_exit(1);
	open(STDOUT, '>', $log) or POSIX::_exit(1);
	open(STDERR, '>&', STDOUT) or POSIX::_exit(1);

	if (POSIX::setsid() < 0) {
		print STDERR "setsid failed: $!\n";
		POSIX::_exit(1);
	}

	# Keep every file the example writes inside the temporary directory
	$ENV{MYAPP_LISTEN}    = "http://127.0.0.1:$port";
	$ENV{MYAPP_CACHE_DIR} = $cache_dir;
	$ENV{MYAPP_LOCK_DIR}  = $lock_dir;
	$ENV{MYAPP_PID_FILE}  = $pid_file;
	$ENV{HYPNOTOAD_FOREGROUND} = 1;
	delete @ENV{qw(HYPNOTOAD_EXE HYPNOTOAD_APP HYPNOTOAD_PID HYPNOTOAD_REV)};

	exec($^X, $hypnotoad, '-f', $script) or do {
		print STDERR "exec failed: $!\n";
		POSIX::_exit(1);
	};
}

$server_group = 1;

my $base = "http://127.0.0.1:$port";
my $ua   = Mojo::UserAgent->new(connect_timeout => 1, request_timeout => 5);
my ($first, $ready);
my $deadline = Time::HiRes::time() + 15;
while (Time::HiRes::time() < $deadline) {
	my $tx = $ua->get("$base/expensive" => {Connection => 'close'});
	if ($tx->res && $tx->res->is_success && ($tx->res->code == 200)) {
		$first = $tx;
		$ready = 1;
		last;
	}
	last unless kill(0, -$server_pid);
	Time::HiRes::sleep(0.1);
}

if (!$ready) {
	fail('the example started under hypnotoad') or diag("Server log:\n" . read_file($log));
	stop_server();
	done_testing();
	return;
}

ok(1, 'the example started under hypnotoad');
is($first->res->headers->header('X-Cache'), 'MISS', 'the first request built the page');

my ($built) = ($first->res->body // '') =~ /Built at ([^<.]+)/;
ok(defined($built), 'the example rendered its template')
	or diag('Body: ' . ($first->res->body // '(none)'));

ok(scalar(glob("$cache_dir/*")), 'the example cached the page under MYAPP_CACHE_DIR');

my $second = $ua->get("$base/expensive" => {Connection => 'close'});
is($second->res->code, 200, 'the second request succeeded');
is($second->res->headers->header('X-Cache'), 'HIT', 'the second request replayed the page');
is($second->res->body, $first->res->body, 'the cached body was replayed unchanged');
like($second->res->body // '', qr/\Q$built\E/, 'the cached page kept its build time');

stop_server();
done_testing();

sub read_file {
	my $path = shift;

	open(my $fh, '<', $path) or return '';
	local $/;
	my $content = <$fh>;
	close($fh);

	return $content // '';
}
