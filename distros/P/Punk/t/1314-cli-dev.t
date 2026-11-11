#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use File::Path ();
use IO::Socket::INET;
use Time::HiRes ();
use POSIX ();
use Test::More;
use Punk::Command;

# punk dev, punk test and punk console --eval, in-process through the capture
# seam. dev forks the server itself, so each dev case runs in a child of this
# test that writes what the seam captured to a file and exits with dev's own
# code; the parent drives the server, changes a watched file, and sends the
# TERM that ends the loop.

plan skip_all => 'Hyperman required' unless eval { require Hyperman; 1 };
plan skip_all => 'fork is not Windows' if $^O eq 'MSWin32';

my $base = File::Temp::tempdir(CLEANUP => 1);
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
sub slurp { my ($f) = @_; open my $fh, '<', $f or return ''; local $/; my $s = <$fh>; close $fh; return $s }
sub app_dir {
    my ($name, $psgi) = @_;
    my $dir = "$base/$name";
    File::Path::make_path("$dir/lib", "$dir/t");
    spew("$dir/app.psgi", $psgi);
    return $dir;
}
sub run_punk {
    my (@argv) = @_;
    my ($out, $err) = ('', '');
    open my $ofh, '>', \$out or die $!;
    open my $efh, '>', \$err or die $!;
    local $Punk::Command::OUT = $ofh;
    local $Punk::Command::ERR = $efh;
    my $code = Punk::Command->main(@argv);
    close $ofh; close $efh;
    return ($code, $out, $err);
}
# dev in a child: its captured output lands in $dir/dev.out and dev.err
sub dev_child {
    my ($dir, @argv) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDIN, '<', '/dev/null';
        my ($code, $out, $err) = run_punk('dev', '--dir', $dir, @argv);
        spew("$dir/dev.out", $out);
        spew("$dir/dev.err", $err);
        Test::Builder->new->no_ending(1);
        exit $code;
    }
    return $pid;
}
sub wait_port {
    my ($port, $up) = @_;
    for (1 .. 80) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return 1 if $up && $s;
        return 1 if !$up && !$s;
        close $s if $s;
        Time::HiRes::sleep(0.1);
    }
    return 0;
}
sub get {
    my ($port, $path) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or return '';
    $s->autoflush(1);
    syswrite $s, "GET $path HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5; while (sysread $s, my $c, 4096) { $buf .= $c } alarm 0 };
    return $buf;
}
sub reap {
    my ($pid) = @_;
    for (1 .. 100) {
        return $? >> 8 if waitpid($pid, POSIX::WNOHANG()) == $pid;
        Time::HiRes::sleep(0.1);
    }
    kill 'KILL', $pid; waitpid $pid, 0;
    return -1;
}
my $port = 25900 + ($$ % 300);

# ---- no application ------------------------------------------------------------
{
    my ($c, $out, $err) = run_punk('dev', '--dir', "$base/nowhere");
    is($c, 2, 'dev with no application exits 2');
    like($err, qr/no application found/, 'and says so');
}

# ---- --no-reload: one server, ended by TERM ---------------------------------------
my $app = app_dir('devapp', "package DevApp;\nuse Punk;\nget '/' => sub { \$_[0]->text('dev:' . (\$ENV{PUNK_ENV} // '-')) };\nDevApp->to_app;\n");
{
    my $pid = dev_child($app, '--port', $port, '--no-reload', '--env', 'staging');
    ok(wait_port($port, 1), 'dev --no-reload brings the application up');
    like(get($port, '/'), qr/dev:staging\z/, 'serving the application with --env in PUNK_ENV');
    kill 'TERM', $pid;
    is(reap($pid), 0, 'TERM ends dev with 0');
    like(slurp("$app/dev.out"), qr/^punk dev  http:\/\/127\.0\.0\.1:$port$/m, 'it printed where it listens');
    unlike(slurp("$app/dev.out"), qr/watching/, 'and watches nothing under --no-reload');
    ok(wait_port($port, 0), 'the server is gone');
}

# ---- a change under a watched directory restarts the server -----------------------
{
    spew("$app/lib/Marker.pm", "package Marker;\n1;\n");
    my $pid = dev_child($app, '--port', $port);
    ok(wait_port($port, 1), 'dev brings the application up');
    like(get($port, '/'), qr/dev:development\z/, 'PUNK_ENV defaults to development');
    Time::HiRes::sleep(0.8);
    spew("$app/lib/Marker.pm", "package Marker;\n# changed\n1;\n");
    utime(time + 5, time + 5, "$app/lib/Marker.pm");
    my $restarted = 0;
    for (1 .. 60) {
        Time::HiRes::sleep(0.1);
        if (slurp("$app/dev.out") =~ /changed, restarting/) { $restarted = 1; last }
    }
    # dev.out is written at exit, so give the loop a moment and end it
    Time::HiRes::sleep(1.5);
    ok(wait_port($port, 1), 'the application is up again after the change');
    kill 'TERM', $pid;
    is(reap($pid), 0, 'TERM ends the reloading dev with 0');
    my $out = slurp("$app/dev.out");
    like($out, qr/^watching  lib$/m, 'it watched the directories that exist');
    like($out, qr/^-- lib\/Marker\.pm changed, restarting --$/m, 'and named the file that changed');
    ok(wait_port($port, 0), 'the server is gone');
}

# ---- an application that exits on its own ------------------------------------------
{
    my $dies = app_dir('devdies', "die \"nope at boot\\n\";\n# Dies->to_app\n");
    my $pid = dev_child($dies, '--port', $port, '--watch', 'lib');
    my $waited = 0;
    for (1 .. 60) {
        Time::HiRes::sleep(0.1);
        last if $waited;
    }
    Time::HiRes::sleep(1.5);
    kill 'TERM', $pid;
    is(reap($pid), 0, 'dev survives an application that exits and ends on TERM');
    like(slurp("$dies/dev.out"), qr/the application exited; waiting for a change/, 'saying that it waits for a change');
}

# ---- punk test ----------------------------------------------------------------------
# App::Prove wants a real stdout for its harness, so punk test runs as the
# installed command would, a subprocess with its streams on files
sub punk_test_code {
    my ($dir, @args) = @_;
    my $q = sub { my $s = shift; $s =~ s/'/'\\''/g; "'$s'" };
    my $inc = join ' ', map { '-I' . $q->(Cwd::abs_path($_) // $_) } grep { !ref } @INC;
    my $bin = $q->(File::Spec->catfile($FindBin::Bin, File::Spec->updir, 'bin', 'punk'));
    system(join ' ', $q->($^X), $inc, $bin, 'test', '--dir', $q->($dir), (map { $q->($_) } @args),
           '>', $q->("$dir/test.out"), '2>', $q->("$dir/test.err"));
    return $? >> 8;
}
{
    my $tapp = app_dir('testapp', "package TApp;\nuse Punk;\nTApp->to_app;\n");
    spew("$tapp/t/ok.t", "use Test::More tests => 1;\nok(1, 'fine');\n");
    is(punk_test_code($tapp), 0, 'punk test exits 0 when the application\'s tests pass') or diag slurp("$tapp/test.out");
    spew("$tapp/t/bad.t", "use Test::More tests => 1;\nok(0, 'broken');\n");
    is(punk_test_code($tapp), 1, 'and 1 when one fails');
    is(punk_test_code($tapp, 't/ok.t'), 0, 'a named file runs alone');
    my $nowhere = "$base/nowhere";
    File::Path::make_path($nowhere);
    is(punk_test_code($nowhere), 2, 'no application is a usage failure');
    like(slurp("$nowhere/test.err"), qr/punk test: no application found/, 'and says so');
}

# ---- punk console --eval ----------------------------------------------------------------
{
    # an application loads once per process, so each console run gets its own
    my $cn = 0;
    my $capp = sub { $cn++; app_dir("consoleapp$cn", "package CApp$cn;\nuse Punk;\nget '/' => sub { \$_[0]->text('c') };\nCApp$cn->to_app;\n") };
    my ($c, $out, $err) = run_punk('console', '--dir', $capp->(), '--eval', 'ref $app');
    is($c, 0, 'console --eval exits 0') or diag $err;
    like($out, qr/Punk::App/, 'and prints what the expression returned');
    ($c, $out, $err) = run_punk('console', '--dir', $capp->(), '--eval', 'die "console boom\n"');
    is($c, 1, 'an expression that dies exits 1');
    like($err, qr/^!! console boom/m, 'with the error marked');
    {
        local *STDIN;
        open STDIN, '<', \"die qq{repl boom\\n};\nref \$app\n" or die $!;
        my ($c2, $out2, $err2) = run_punk('console', '--dir', $capp->());
        is($c2, 0, 'a console fed on STDIN exits 0 at its end') or diag $err2;
        like($out2 . $err2, qr/^!! repl boom/m, 'a line that dies is reported');
        like($out2, qr/CApp\d+/, 'and the next line still runs');
    }
    ($c, $out, $err) = run_punk('console', '--dir', $capp->(), '--eval', '()');
    is($c, 0, 'an expression returning nothing prints nothing');
    is($out, '', 'exactly nothing');
}

done_testing;
