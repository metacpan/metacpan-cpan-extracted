#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use Test::More;
use Punk::Command;

# `punk serve` - the argument shape in-process through the documented capture
# seam, then one real server to prove the directory actually reaches a socket.

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

my $dir = File::Temp->newdir;
{
    open my $fh, '>', "$dir/index.html" or die $!;
    print $fh "<h1>root</h1>";
    close $fh;
    mkdir "$dir/sub";
    open $fh, '>', "$dir/sub/index.html" or die $!;
    print $fh "<h1>sub</h1>";
    close $fh;
    open $fh, '>', "$dir/style.css" or die $!;
    print $fh "body{color:red}";
    close $fh;
}

# ---- it is in the command list -----------------------------------------------

{
    my ($code, $out) = run_punk();
    is($code, 0, 'bare punk lists the commands');
    like($out, qr/^\s+serve \[DIR\]\s+serve a directory of files over HTTP$/m,
        'serve is listed with its display form and abstract');
}

# ---- generated help ----------------------------------------------------------

{
    my ($code, $out) = run_punk('serve', '--help');
    is($code, 0, 'punk serve --help exits 0');
    like($out, qr/usage: punk serve \[DIR\] \[options\]/, 'usage line');
    like($out, qr/--port N\s+listen port \(default: 8000\)/, 'port default');
    like($out, qr/--host ADDR\s+listen address \(default: 127\.0\.0\.1\)/,
        'host default');
    like($out, qr/--index NAME\s+.*\(default: index\.html\)/, 'index default');
    like($out, qr/--no-index/, 'no-index is offered');
    like($out, qr/--list/,     'list is offered');
    like($out, qr/--quiet/,    'quiet is offered');

    # the shared --dir is about finding an application; this one is not
    like($out, qr/--dir PATH\s+the directory to serve/,
        'serve declares its own --dir');
    unlike($out, qr/--dir PATH\s+the application/,
        '... which displaces the shared one rather than joining it');
    like($out, qr/punk serve \.\/public --port 3000/, 'examples are shown');
}

# ---- misuse ------------------------------------------------------------------

{
    my ($code, $out, $err) = run_punk('serve', 'one', 'two');
    is($code, 2, 'a second positional is misuse');
    like($err, qr/punk serve: unexpected argument 'two'/, '... naming it');
    like($err, qr/usage: punk serve/, '... with the usage');
}

{
    my ($code, $out, $err) = run_punk('serve', "$dir/nope");
    is($code, 1, 'a missing directory is an environment failure');
    like($err, qr/punk serve: no such directory: \Q$dir\E\/nope/,
        '... naming the directory');
}

{
    my ($code, $out, $err) = run_punk('serve', '--nonsense');
    is($code, 2, 'an unknown option is misuse');
}

# ---- a real server -----------------------------------------------------------

SKIP: {
    skip 'Hyperman is not installed', 8 unless eval { require Hyperman; 1 };
    skip 'no fork', 8 unless eval { my $p = fork; defined $p
        or die; if (!$p) { require POSIX; POSIX::_exit(0) } waitpid $p, 0; 1 };
    require IO::Socket::INET;
    require POSIX;

    my $port = 27400 + ($$ % 300);
    my $pid  = fork // die "fork: $!";
    if (!$pid) {
        # The child must not keep the TAP pipe: a forked server holding
        # stdout makes the harness wait for a process that is never going to
        # exit, and the failure looks like a hang long after every test
        # passed.
        open STDIN,  '<', '/dev/null';
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        eval { Punk::Command->main('serve', "$dir",
                                   '--port', $port, '--quiet') };
        Test::Builder->new->no_ending(1);
        exit 0;
    }

    my $host = "127.0.0.1:$port";
    my $up   = 0;
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => $host);
        if ($s) { close $s; $up = 1; last }
        select undef, undef, undef, 0.1;
    }

    unless ($up) {
        kill 'KILL', $pid; waitpid $pid, 0;
        skip 'the server did not come up', 8;
    }

    my $get = sub {
        my ($path) = @_;
        my $s = IO::Socket::INET->new(PeerAddr => $host) or return;
        print $s "GET $path HTTP/1.0\r\nHost: $host\r\n\r\n";
        local $/;
        my $r = <$s>;
        close $s;
        return $r // '';
    };

    like($get->('/'), qr{^HTTP/1\.[01] 200}, '/ is served');
    like($get->('/'), qr{<h1>root</h1>},     '... from index.html');
    like($get->('/sub/'), qr{<h1>sub</h1>},  '/sub/ resolves its index');
    like($get->('/sub'),  qr{<h1>sub</h1>},
        '/sub without the slash resolves it too');
    like($get->('/style.css'), qr{Content-Type: text/css}i,
        'a file keeps its content type');
    like($get->('/nope'), qr{^HTTP/1\.[01] 404}, 'a missing path is a 404');
    like($get->('/../1312-serve.t'), qr{^HTTP/1\.[01] 404},
        'traversal out of the directory is a 404');
    ok(1, 'the server survived the run');

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;
