#!/usr/bin/env perl
# Test a terminal program: run it in a pseudo-terminal, send keys, assert on the screen.
use 5.010;
use strict;
use warnings;
use Test::More;
use Term::Ghostty;

BEGIN { eval { require IO::Pty; 1 } or die "tui_test_framework.pl needs IO::Pty (cpanm IO::Pty)\n" }

package TUI::Tester;

use POSIX qw(WNOHANG);
use Test::More;
use Time::HiRes qw(time sleep);

sub spawn {
    my ($class, %args) = @_;
    my $cols = $args{cols} // 80;
    my $rows = $args{rows} // 24;

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
        exec { $args{cmd}[0] } @{ $args{cmd} } or print STDERR "exec $args{cmd}[0]: $!\n";
        POSIX::_exit(127);
    }
    $pty->close_slave;
    $pty->blocking(0);

    my $vt = Term::Ghostty->new(
        cols         => $cols,
        rows         => $rows,
        on_pty_write => sub { syswrite $pty, $_[1] },
    );
    return bless { pty => $pty, pid => $pid, vt => $vt }, $class;
}

sub pump {
    my ($self, $timeout) = @_;
    my $rin = '';
    vec($rin, fileno $self->{pty}, 1) = 1;
    return unless select(my $rout = $rin, undef, undef, $timeout) > 0;
    my $n = sysread $self->{pty}, my $buf, 65536;
    return if !defined $n && $!{EAGAIN};
    if ($n) { $self->{vt}->feed($buf) } else { $self->{eof} = 1 }
}

sub send {
    my ($self, $text) = @_;
    utf8::encode(my $bytes = $text);
    while (length $bytes) {
        my $n = syswrite $self->{pty}, $bytes;
        if (defined $n)    { substr $bytes, 0, $n, '' }
        elsif ($!{EAGAIN}) { $self->pump(0.05) }
        else               { die "write to pty: $!\n" }
    }
}

sub eventually {
    my ($self, $check, $timeout) = @_;
    my $deadline = time + ($timeout // 3);
    until ($check->()) {
        return 0 if $self->{eof} || time > $deadline;
        $self->pump(0.05);
    }
    return 1;
}

sub screen { $_[0]{vt}->get_text }
sub title  { $_[0]{vt}->title }

sub screen_like {
    my ($self, $re, $name) = @_;
    ok($self->eventually(sub { $self->screen =~ $re }), $name)
        or diag("screen:\n" . $self->screen);
}

sub cursor_is {
    my ($self, $x, $y, $name) = @_;
    my $at = sub { my ($cx, $cy) = $self->{vt}->cursor_pos; $cx == $x && $cy == $y };
    ok($self->eventually($at), $name)
        or diag(sprintf 'cursor is at (%d, %d)', $self->{vt}->cursor_pos);
}

sub exit_status {
    my ($self) = @_;
    $self->eventually(sub { $self->{eof} });
    return $self->stop;
}

sub stop {
    my ($self) = @_;
    local $?;
    close delete $self->{pty} if $self->{pty};
    my $pid = delete $self->{pid} or return;
    kill 'HUP', -$pid;
    for (1 .. 20) {
        return $? if waitpid($pid, WNOHANG);
        sleep 0.1;
    }
    kill 'KILL', -$pid;
    waitpid $pid, 0;
    return $?;
}

sub DESTROY { $_[0]->stop }

package main;

my $app = <<'APP';
$| = 1;
print "\e]2;Fruit picker\a\e[2J\e[H";
print "Pick a fruit:\n  a) apple\n  b) banana\n\nChoice: ";
chomp(my $key = <STDIN> // '');
my %fruit = (a => 'apple', b => 'banana');
print "You picked: ", $fruit{$key} // 'nothing', "\n";
exit($fruit{$key} ? 0 : 1);
APP

my $t = TUI::Tester->spawn(cmd => [$^X, '-e', $app], cols => 40, rows => 10);

$t->screen_like(qr/^Choice:/m, 'menu is drawn');
$t->cursor_is(8, 4, 'cursor waits after "Choice: "');
is($t->title, 'Fruit picker', 'window title is set');

$t->send("b\r");
$t->screen_like(qr/^You picked: banana$/m, 'choosing b picks banana');
is($t->exit_status, 0, 'program exits with status 0');

done_testing;
