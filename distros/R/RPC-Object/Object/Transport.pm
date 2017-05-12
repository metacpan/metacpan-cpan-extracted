package RPC::Object::Transport;
use constant RETRY_MAX => 10;
use constant RETRY_WAIT => 2;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;

sub new {
    my ($class, $config, $semaphore) = @_;
    my $socket;
    my $retry = 0;
    while (1) {
        $socket = IO::Socket::INET->new(%$config);
        croak "exceed maximum number of retry: $!" if $retry > RETRY_MAX;
        next unless defined $socket;
        binmode $socket;
        last;
    }
    continue {
        ++$retry;
        sleep RETRY_WAIT;
    }
    my $self = { socket => $socket,
                 retry => $retry,
                 semaphore => $semaphore,
               };
    bless $self, $class;
    return $self;
}

sub request {
    my ($self, $req) = @_;
    my $socket = $self->{socket};
    my $retry = $self->{retry};
    print $socket pack('na*', $retry, $req) or croak "fail to send request: $!";
    $socket->shutdown(1) or croak $!;
    my $res = do { local $/; <$socket> };
    croak "fail to receive response: $!" unless defined $res;
    $socket->close() or croak $!;
    my ($state, $val) = unpack('ca*', $res);
    croak $val if $state eq 'e';
    return $val;
}

sub response {
    my ($self, $handler) = @_;
    my $socket = $self->{socket};
    my $semaphore = $self->{semaphore};
    $semaphore->down() if defined $semaphore;
    my $peer = $socket->accept();
    $semaphore->up() if defined $semaphore;
    return unless defined $peer;
    binmode $peer;
    my $req = do { local $/; <$peer> };
    croak "fail to receive request: $!" unless defined $req;
    my $res = eval { $handler->(unpack('na*', $req)) };
    $res = '' unless defined $res;
    my $val = $@ ? pack('aa*', 'e', $@) : pack('aa*', 'o', $res);
    print $peer $val or croak "fail to send response: $!";
    $peer->shutdown(2) or croak $!;
    $peer->close() or croak $!;
    return 1;
}

1;

