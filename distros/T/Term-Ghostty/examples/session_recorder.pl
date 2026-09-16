#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use POSIX qw(WNOHANG);
use Time::HiRes qw(sleep);
use Getopt::Long qw(GetOptions :config require_order);
use Term::Ghostty;

BEGIN { eval { require IO::Pty; 1 } or die "session_recorder.pl needs IO::Pty (cpanm IO::Pty)\n" }

my $outfile = 'session_transcript.html';
my $format  = 'html';
my ($cols, $rows);

GetOptions(
    'out=s'    => \$outfile,
    'format=s' => \$format,
    'cols=i'   => \$cols,
    'rows=i'   => \$rows,
    'help'     => sub { usage(0) },
) or usage(1);
usage(1) unless $format =~ /\A(?:html|plain|vt)\z/;

sub usage {
    my ($exit_code) = @_;
    print { $exit_code ? *STDERR : *STDOUT } <<"USAGE";
Usage: $0 [options] [--] [command args...]

Run a command (default: \$SHELL) in a pseudo-terminal, pass it through to this
terminal, and save the whole session as a transcript when it ends.

Options:
  --out <filename>   Transcript file (default: session_transcript.html)
  --format <type>    html, plain or vt (default: html)
  --cols <N>         Columns (default: this terminal's width, else 100)
  --rows <N>         Rows (default: this terminal's height, else 35)
  --help             Show this help

Examples:
  $0 --out build.html -- make
  $0 --format plain --out session.txt
USAGE
    exit $exit_code;
}

my @cmd = @ARGV ? @ARGV : ($ENV{SHELL} || '/bin/sh');
my $interactive = -t STDIN;

my $pty = IO::Pty->new;
my ($tty_rows, $tty_cols);
if ($interactive) {
    $pty->slave->clone_winsize_from(\*STDIN);
    ($tty_rows, $tty_cols) = $pty->slave->get_winsize;
}
$rows //= $tty_rows || 35;
$cols //= $tty_cols || 100;
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
    $ENV{TERM} //= 'xterm-256color';
    exec { $cmd[0] } @cmd or print STDERR "exec $cmd[0]: $!\n";
    POSIX::_exit(127);
}
$pty->close_slave;

# With a real terminal attached, it answers the program's queries itself.
my $vt = Term::Ghostty->new(
    cols           => $cols,
    rows           => $rows,
    max_scrollback => 100_000,
    on_pty_write   => $interactive && -t STDOUT ? undef : sub { print $pty $_[1] },
);

my $saved_tty;
END { local $?; system 'stty', $saved_tty if defined $saved_tty }

print STDERR "[recording '@cmd' to $outfile]\n";
if ($interactive) {
    chomp($saved_tty = `stty -g`);
    system 'stty', 'raw', '-echo';
}

my $stop = 0;
$SIG{$_} = sub { $stop = 1 } for qw(INT TERM HUP);
binmode STDOUT;
$| = 1;

my $stdin_open = 1;
my $status;
until ($stop) {
    my $rin = '';
    vec($rin, fileno $pty, 1) = 1;
    vec($rin, fileno STDIN, 1) = 1 if $stdin_open;
    my $ready = select(my $rout = $rin, undef, undef, 0.2);
    next if $ready < 0;

    if ($ready && $stdin_open && vec($rout, fileno STDIN, 1)) {
        if (sysread STDIN, my $in, 4096) { print $pty $in }
        else                              { $stdin_open = 0 }
    }
    if ($ready && vec($rout, fileno $pty, 1)) {
        sysread $pty, my $buf, 65536 or last;
        print $buf;
        $vt->feed($buf);
    } elsif (waitpid $pid, WNOHANG) {
        $status = $?;
        last;
    }
}

sub reap {
    kill 'HUP', -$pid;
    for (1 .. 20) {
        return $? if waitpid $pid, WNOHANG;
        sleep 0.05;
    }
    kill 'KILL', -$pid;
    waitpid $pid, 0;
    return $?;
}

close $pty;
$status //= reap();
system 'stty', $saved_tty if defined $saved_tty;
undef $saved_tty;

my $out = $vt->format(format => $format, scrollback => 1);
if ($format eq 'html') {
    utf8::decode(my $title = "@cmd");
    $title =~ s/([&<>"])/'&#' . ord($1) . ';'/ge;
    $out = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Session: $title</title>
<style>
body { margin: 0; padding: 24px; background: #111; font-family: sans-serif; }
.window { display: inline-block; background: #1d1f21; color: #c5c8c6; border-radius: 8px; overflow: hidden; }
.bar { background: #282a2e; color: #969896; padding: 8px 16px; font-size: 12px; }
.screen { padding: 16px; }
</style>
</head>
<body>
<div class="window">
<div class="bar">$title</div>
<div class="screen">$out</div>
</div>
</body>
</html>
HTML
} else {
    $out .= "\n";
}

open my $fh, '>:encoding(UTF-8)', $outfile or die "Cannot write '$outfile': $!\n";
print $fh $out;
close $fh or die "Cannot write '$outfile': $!\n";

print STDERR "\n[session ended, transcript saved to $outfile]\n";
exit($status & 127 ? 128 + ($status & 127) : $status >> 8);
