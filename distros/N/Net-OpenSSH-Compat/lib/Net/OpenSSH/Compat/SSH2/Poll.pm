package Net::OpenSSH::Compat::SSH2;

use strict;
use warnings;
use Carp;
use POSIX ();

use IO::Poll qw( POLLIN
                 POLLOUT
                 POLLERR
                 POLLHUP
                 POLLNVAL
                 POLLPRI
                 POLLRDNORM
                 POLLWRNORM
                 POLLRDBAND
                 POLLWRBAND
                 POLLNORM );

my %libssh2_cts =   ( in              => 0x0001,
                      pri             => 0x0002,
                      ext             => 0x0002,
                      out             => 0x0004,
                      err             => 0x0008,
                      hup             => 0x0010,
                      session_closed  => 0x0010,
                      nval            => 0x0020,
                      ex              => 0x0040,
                      channel_closed  => 0x0080,
                      listener_closed => 0x0080 );

my %poll_mask =     ( in  => POLLIN,
                      out => POLLOUT,
                      pri => POLLPRI,
                      err => POLLERR,
                      hup => POLLHUP);

my %poll_event_in = ( in => 1,
                      out => 1,
                      pri => 1);

sub _poll {
    my ($self, $timeout, $e) = @_;

    my $poll = IO::Poll->new;
    my @err;
    my @is_channel;
    my @channel;
    my @channel_pid;
    my @session_pid;
    my %pids;

    for my $ix (0..$#$e) {
        my $hash = $e->[$ix];
        my $fh = $hash->{handle};
        my $channel;
        if (UNIVERSAL::isa("Net::OpenSSH::Compat::SSH2::Channel", $fh)) {
            $is_channel[$ix] = 1;
            $channel = $channel[$ix] = $fh;
            next unless $fh->_state eq 'exec';
            $channel_pid[$ix] = $fh->_hash->{pid};
            $session_pid[$ix] = $fh->_parent->{ssh}->get_master_pid;
        }

        my $events = $hash->{events};
        unless (ref $events) {
            my @a;
            while (my ($k, $v) = each %libssh2_cts) {
                push @a, $k if (($events & $v) == $v);
            }
            $events = \@a;
        }
        for my $event (@$events) {
            if ($poll_event_in{$event}) {
                $poll->mask($fh, $poll_mask{$event});
            }
            elsif ($event eq 'ext') {
                if ($channel) {
                    my $err = $err[$ix] = $channel->_hash->{err};
                    $err and $poll->mask($err, POLLIN);
                }
            }
            else {
                # croak "unsupported event $event"
            }
        }
    }
    $pids{$_} = undef for (grep defined, @channel_pid, @session_pid);

    {
        my $sigchl;
        local $SIG{CHLD} = sub { $sigchl = 1 };
        $timeout = 0 if _check_pids(\%pids);
        return -1 if ($poll->poll($timeout) < 0 and !$sigchl)
    }
    _check_pids(\%pids);
    my $r = 0;
    for my $ix (0..$#$e) {
        my $hash = $e->[$ix];
        my $handle = $hash->{handle};
        my $selected = $poll->events($handle);
        my @revents;
        while (my ($event, $mask) = each %poll_mask) {
            if (($selected & $mask) == $mask) {
                push @revents, $event;
            }
        }
        if ($is_channel[$ix]) {
            my $err = $err[$ix];
            if ($err and
                (($poll->events($err) & POLLIN) == POLLIN)) {
                push @revents, 'ext';
            }
            if (my $cp = $channel_pid[$ix]) {
                $handle->_slave_exited($pids{$cp}) if defined $pids{$cp};
            }
            unless ($handle->_hash->{pid}) {
                push @revents, 'channel_closed';
            }
            if (my $sp = $session_pid[$ix]) {
                $handle->_master_exited($pids{$sp}) if defined $pids{$sp};
            }
            if ($handle->_parent->_state == 'failed') {
                push @revents, 'session_closed';
            }
        }
        my $v = 0;
        if (@revents) {
            $r++;
            for my $k (@revents) {
                $v |= $libssh2_cts{$k};
            }
        }
        $hash->{revents} = {value => $v, map { $_ => 1} @revents }
    }
    return $r;
}

sub _check_pids {
    my $pids = shift;
    my $ok;
    while (my ($k, $v) = each %$pids) {
        next if defined $v;
        if (waitpid($k, POSIX::WNOHANG()) == $k) {
            $v = $?;
        }
    }
}

1;
