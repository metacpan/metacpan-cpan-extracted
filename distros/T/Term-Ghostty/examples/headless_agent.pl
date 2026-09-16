#!/usr/bin/env perl
# Drive an interactive bash in a headless terminal and read back its screen.
use 5.010;
use strict;
use warnings;
use Term::Ghostty;

BEGIN { eval { require IO::Pty; 1 } or die "headless_agent.pl needs IO::Pty (cpanm IO::Pty)\n" }

package HeadlessTerminal;

use POSIX qw(WNOHANG);
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
        %ENV = (%ENV, TERM => 'xterm-256color', %{ $args{env} // {} });
        exec { $args{cmd}[0] } @{ $args{cmd} } or print STDERR "exec $args{cmd}[0]: $!\n";
        POSIX::_exit(127);
    }
    $pty->close_slave;
    $pty->blocking(0);

    my $verbose = $args{verbose};
    my $vt = Term::Ghostty->new(
        cols             => $cols,
        rows             => $rows,
        on_pty_write     => sub { syswrite $pty, $_[1] },
        on_title_changed => sub { print STDERR "[title: $_[1]]\n" if $verbose },
        on_bell          => sub { print STDERR "[bell]\n" if $verbose },
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

sub wait_for {
    my ($self, $cond, $timeout) = @_;
    my $deadline = time + ($timeout // 5);
    until ($cond->($self)) {
        return 0 if $self->{eof} || time > $deadline;
        $self->pump(0.05);
    }
    return 1;
}

# PS1 carries bash's command number, so a stale prompt never passes for a new one.
sub prompt_number {
    my ($self) = @_;
    return ($self->{vt}->get_text =~ /^\[(\d+)\]\$/mg)[-1] // 0;
}

sub run {
    my ($self, $cmd, $timeout) = @_;
    my $n = $self->prompt_number;
    $self->send("$cmd\r");
    $self->wait_for(sub { $_[0]->prompt_number > $n }, $timeout)
        or die "timed out waiting for: $cmd\n";
}

sub screen     { $_[0]{vt}->get_text }
sub cursor_pos { $_[0]{vt}->cursor_pos }
sub title      { $_[0]{vt}->title }

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

binmode $_, ':encoding(UTF-8)' for \*STDOUT, \*STDERR;
STDERR->autoflush(1);

my $sh = HeadlessTerminal->spawn(
    cmd     => [qw(bash --norc --noprofile)],
    env     => { PS1 => '[\#]$ ' },
    cols    => 100,
    rows    => 20,
    verbose => 1,
);
$sh->wait_for(sub { $_[0]->prompt_number }) or die "shell did not start\n";

$sh->run(q{printf 'Color: \033[32mOK\033[0m  Unicode: \342\234\224 \360\237\232\200\n'});
$sh->run('expr 1900 + 126');

# Term::Ghostty answers this cursor position query through on_pty_write.
$sh->run(q{stty -echo; printf '\033[6n'; IFS='[;' read -rd R _ row col; stty echo; echo "cursor reported at row $row, column $col"});

$sh->run(q{printf '\033]2;Demo Finished\007'});

my ($cx, $cy) = $sh->cursor_pos;
print "Cursor: ($cx, $cy)\n";
print "Title:  ", $sh->title, "\n\n";
print "=== Screen ===\n", $sh->screen, "\n==============\n";

$sh->send("exit\r");
$sh->wait_for(sub { $_[0]{eof} });
printf "bash exited with status %d\n", $sh->stop >> 8;
