package Queue::Gearman::Socket;
use strict;
use warnings;
use utf8;

use Socket qw/IPPROTO_TCP TCP_NODELAY/;
use Errno qw(EAGAIN ECONNRESET EINPROGRESS EINTR EWOULDBLOCK ECONNABORTED EISCONN);
use IO::Socket::INET;
use IO::Select;
use Time::HiRes;

use Queue::Gearman::Message qw/:functions :headers HEADER_BYTES/;
use Queue::Gearman::Util qw/dumper/;

use constant WIN32 => $^O eq 'MSWin32';
use constant DEBUG => $ENV{QUEUE_GEARMAN_DEBUG};

use Class::Accessor::Lite new => 1, ro => [qw/
    server
    timeout
    inactivity_timeout
    on_connect_do
/];

sub _connect {
    my $self = shift;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->server,
        Blocking => 0,
        Proto    => 'tcp',
        Timeout  => $self->timeout,
    ) or die $!;
    $sock->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1) or die $!;
    $sock->autoflush(1);

    $self->{owner_pid} = $$;
    $self->{sock}      = $sock;
    $self->{select}    = IO::Select->new($sock);

    $self->{on_connect_do}->($self) if defined $self->{on_connect_do};

    return $sock;
}

sub sock {
    my $self = shift;
    $self->_reconnect_without_close() if exists $self->{owner_pid} && $self->{owner_pid} != $$;
    return $self->{sock} if exists $self->{sock};
    return $self->_connect();
}

sub _select {
    my $self = shift;
    $self->_reconnect_without_close() if exists $self->{owner_pid} && $self->{owner_pid} != $$;
    return $self->{select} if exists $self->{select};
    return $self->_connect() && $self->_select();
}

sub _reconnect_without_close {
    my $self = shift;
    delete $self->{select};
    delete $self->{sock};
    delete $self->{owner_pid};
    return $self->_connect();
}

sub recv :method {
    my $self = shift;

    my ($context, $msgtype, $bytes) = do {
        my $header;
        $self->_recv(\$header, HEADER_BYTES) or return;
        parse_header($header);
    };

    my @args;
    if ($bytes) {
        my $args;
        $self->_recv(\$args, $bytes) or return;
        @args = parse_args($args);
    }

    my %res = (
        context => $context,
        msgtype => $msgtype,
        bytes   => $bytes,
        args    => \@args,
    );
    warn 'recv: ', dumper(\%res) if DEBUG;
    return \%res;
}

sub _recv {
    my ($self, $buffer, $length) = @_;

    my $timeout_at = Time::HiRes::time + $self->inactivity_timeout;

    my $recieved = 0;
    while ($recieved < $length) {
        my $ret = $self->_read_timeout($buffer, $length - $recieved, $recieved, $timeout_at);
        unless (defined $ret) {
            warn "failed to recv: $!";
            return;
        }
        $recieved += $ret;
    }

    warn '_recv: ', dumper($$buffer) if DEBUG;
    return $recieved;
}

# returns (positive) number of bytes read, or undef if the socket is to be closed
sub _read_timeout {
    my ($self, $buffer, $length, $offset, $timeout_at) = @_;
    my $sock   = $self->sock;
    my $select = $self->_select;

    my $ret;
    while (1) {
        # try to do the IO
        defined($ret = $sock->sysread($$buffer, $length, $offset))
            and return $ret;
        if ($! == EAGAIN || $! == EWOULDBLOCK || (WIN32 && $! == EISCONN)) {
            # passthru
        } elsif ($! == EINTR) {
            # otherwise passthru
        } else {
            return undef;
        }

        # on EINTR/EAGAIN/EWOULDBLOCK
        my $timeout = $timeout_at - Time::HiRes::time;
        return undef if $timeout <= 0;
        $select->can_read($timeout) or return undef;
    }
}

sub send :method {
    my $self = shift;
    warn 'send: ', dumper([unpack('a4N', $_[0]), @_[1..$#_]]) if DEBUG;
    return $self->_send(build_message(@_));
}

sub _send {
    my ($self, $message, $length) = @_;
    $length ||= length $message;

    my $timeout_at = Time::HiRes::time + $self->inactivity_timeout;

    my $sent = 0;
    while ($sent < $length) {
        my $ret = $self->_write_timeout($message, $length - $sent, $sent, $timeout_at);
        unless (defined $ret) {
            warn "failed to send: $!";
            return;
        }
        $sent += $ret;
    }

    warn '_send: ', dumper($message) if DEBUG;
    return $sent;
}

# returns (positive) number of bytes written, or undef if the socket is to be closed
sub _write_timeout {
    my ($self, $buffer, $length, $offset, $timeout_at) = @_;
    my $sock   = $self->sock;
    my $select = $self->_select;

    my $ret;
    while (1) {
        # try to do the IO
        defined($ret = $sock->syswrite($buffer, $length, $offset))
            and return $ret;
        if ($! == EAGAIN || $! == EWOULDBLOCK || (WIN32 && $! == EISCONN)) {
            # passthru
        } elsif ($! == EINTR) {
            # otherwise passthru
        } else {
            return undef;
        }

        # on EINTR/EAGAIN/EWOULDBLOCK
        my $timeout = $timeout_at - Time::HiRes::time;
        return undef if $timeout <= 0;
        $select->can_write($timeout) or return undef;
    }
}

sub disconnect {
    my $self = shift;
    return unless exists $self->{sock};
    $self->{sock}->close();
    delete $self->{select};
    delete $self->{sock};
    delete $self->{owner_pid};
}

sub DESTROY {
    my $self = shift;
    $self->disconnect();
}

1;
__END__
