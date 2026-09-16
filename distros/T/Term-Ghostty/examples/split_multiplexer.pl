#!/usr/bin/env perl
# Run two commands side by side, each in its own pseudo-terminal and Term::Ghostty.
use 5.010;
use strict;
use warnings;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time sleep);
use Getopt::Long qw(GetOptions);
use Term::Ghostty;

BEGIN { eval { require IO::Pty; 1 } or die "split_multiplexer.pl needs IO::Pty (cpanm IO::Pty)\n" }

my $cmd1     = 'vmstat 1';
my $cmd2     = 'df -h';
my $duration = 3;
my $cols     = 42;
my $rows     = 14;

GetOptions(
    'cmd1=s'     => \$cmd1,
    'cmd2=s'     => \$cmd2,
    'duration=f' => \$duration,
    'cols=i'     => \$cols,
    'rows=i'     => \$rows,
) or die "Usage: $0 [--cmd1 CMD] [--cmd2 CMD] [--duration SECS] [--cols N] [--rows N]\n";

sub spawn_pane {
    my ($cmd) = @_;
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
        on_pty_write => sub { syswrite $pty, $_[1] },
    );
    utf8::decode(my $label = $cmd);
    return { label => substr($label, 0, $cols - 2), pty => $pty, pid => $pid, vt => $vt };
}

sub reap {
    my ($pid) = @_;
    kill 'TERM', -$pid;
    for (1 .. 20) {
        return if waitpid($pid, WNOHANG);
        sleep 0.05;
    }
    kill 'KILL', -$pid;
    waitpid $pid, 0;
}

my @panes = (spawn_pane($cmd1), spawn_pane($cmd2));
my $end   = time + $duration;

sub draw {
    my ($left, $right) = map { [split /\n/, $_->{vt}->get_text] } @panes;
    my $out = sprintf "\e[1;1H\e[2K\e[1;37;44m %s \e[0m\e[1;%dH\e[1;37;42m %s \e[0m",
        $panes[0]{label}, $cols + 4, $panes[1]{label};
    for my $r (0 .. $rows - 1) {
        my $y = $r + 2;
        $out .= "\e[$y;1H\e[2K" . ($left->[$r] // '')
              . "\e[$y;" . ($cols + 2) . "H\x{2502} " . ($right->[$r] // '');
    }
    $out .= sprintf "\e[%d;1H\e[2K%.1fs left", $rows + 2, $end > time ? $end - time : 0;
    print $out;
}

binmode STDOUT, ':encoding(UTF-8)';
$| = 1;
my $stop = 0;
$SIG{INT} = $SIG{TERM} = sub { $stop = 1 };
print "\e[?25l\e[H\e[2J";

while (!$stop && time < $end) {
    my $rin = '';
    vec($rin, fileno $_->{pty}, 1) = 1 for grep { !$_->{done} } @panes;
    if (select(my $rout = $rin, undef, undef, 0.1) > 0) {
        for my $p (grep { !$_->{done} && vec($rout, fileno $_->{pty}, 1) } @panes) {
            if (sysread $p->{pty}, my $buf, 65536) { $p->{vt}->feed($buf) }
            else                                    { $p->{done} = 1 }
        }
    }
    draw();
}

print "\e[", $rows + 3, ";1H\e[?25h";

for my $p (@panes) {
    close $p->{pty};
    reap($p->{pid});
}
