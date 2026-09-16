#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use IO::Socket::INET;
use POSIX qw(WNOHANG);
use Time::HiRes qw(sleep);
use Getopt::Long qw(GetOptions);
use Term::Ghostty;

BEGIN { eval { require IO::Pty; 1 } or die "live_web_monitor.pl needs IO::Pty (cpanm IO::Pty)\n" }

my $port = 8080;
my $bind = '127.0.0.1';
my $cmd  = 'top -d 1';
my $cols = 90;
my $rows = 30;

my $usage = <<"USAGE";
Usage: $0 [options]

Run a command in a headless terminal and serve its screen as a self-refreshing
web page.

Options:
  --port <port>     HTTP port (default: 8080)
  --bind <addr>     Address to listen on (default: 127.0.0.1)
  --cmd <command>   Command to run (default: "top -d 1")
  --cols <cols>     Terminal columns (default: 90)
  --rows <rows>     Terminal rows (default: 30)
  --help            Show this help message
USAGE

GetOptions(
    'port=i' => \$port,
    'bind=s' => \$bind,
    'cmd=s'  => \$cmd,
    'cols=i' => \$cols,
    'rows=i' => \$rows,
    'help'   => sub { print $usage; exit },
) or die $usage;

my $server = IO::Socket::INET->new(
    LocalAddr => $bind,
    LocalPort => $port,
    Listen    => 10,
    ReuseAddr => 1,
) or die "Cannot listen on $bind:$port: $@\n";

my $pty = IO::Pty->new;
$pty->slave->set_winsize($rows, $cols);

my $pid = fork // die "fork: $!\n";
if (!$pid) {
    $pty->make_slave_controlling_terminal;
    my $tty = $pty->slave;
    close $pty;
    open STDIN,  '<&', $tty or POSIX::_exit(127);
    open STDOUT, '>&', $tty or POSIX::_exit(127);
    open STDERR, '>&', $tty or POSIX::_exit(127);
    close $tty;
    $ENV{TERM} = 'xterm-256color';
    exec '/bin/sh', '-c', $cmd or POSIX::_exit(127);
}
$pty->close_slave;

my $vt = Term::Ghostty->new(
    cols         => $cols,
    rows         => $rows,
    on_pty_write => sub { syswrite $pty, $_[1] if $pty },
);

utf8::decode(my $title = $cmd);
$title =~ s/([&<>"])/'&#' . ord($1) . ';'/ge;

sub page {
    my $screen = $vt->get_html;
    return <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="1">
<title>$title</title>
<style>
body { margin: 0; padding: 20px; background: #111; }
.screen { display: inline-block; padding: 16px; border-radius: 8px; background: #1d1f21; color: #c5c8c6; }
</style>
</head>
<body>
<div class="screen">$screen</div>
</body>
</html>
HTML
}

sub serve {
    my ($client) = @_;
    my $rin = '';
    vec($rin, fileno $client, 1) = 1;
    my $req = '';
    sysread $client, $req, 4096 if select(my $rout = $rin, undef, undef, 1) > 0;
    my ($status, $body) = $req =~ m{\AGET / HTTP/}
        ? ('200 OK', page())
        : ('404 Not Found', "Not found\n");
    utf8::encode($body);
    print $client "HTTP/1.1 $status\r\n",
        "Content-Type: text/html; charset=utf-8\r\n",
        "Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'\r\n",
        "Cache-Control: no-store\r\n",
        "Content-Length: ", length($body), "\r\n",
        "Connection: close\r\n\r\n",
        $body;
    close $client;
}

sub reap {
    kill 'HUP', -$pid;
    for (1 .. 20) {
        return if waitpid($pid, WNOHANG);
        sleep 0.05;
    }
    kill 'KILL', -$pid;
    waitpid $pid, 0;
}

$SIG{PIPE} = 'IGNORE';
my $stop = 0;
$SIG{INT} = $SIG{TERM} = sub { $stop = 1 };

$| = 1;
print "Serving '$cmd' at http://$bind:$port/ (Ctrl-C to stop)\n";

until ($stop) {
    my $rin = '';
    vec($rin, fileno $server, 1) = 1;
    vec($rin, fileno $pty, 1) = 1 if $pty;
    next unless select(my $rout = $rin, undef, undef, undef) > 0;

    if ($pty && vec($rout, fileno $pty, 1)) {
        if (sysread $pty, my $buf, 65536) {
            $vt->feed($buf);
        } else {
            close $pty;
            undef $pty;
            reap();
            print "Command exited; still serving its last screen\n";
        }
    }
    if (vec($rout, fileno $server, 1) and my $client = $server->accept) {
        serve($client);
    }
}

if ($pty) {
    close $pty;
    reap();
}
print "Stopped\n";
