# Minecraft implementation of the RCON protocol.

package Net::RCON::Minecraft;

use 5.008;

use Mouse;
use Mouse::Util::TypeConstraints;
use Net::RCON::Minecraft::Response;
use IO::Socket::IP;
use IO::Select;
use Carp;

no warnings 'uninitialized';

our $VERSION = '0.01';

use constant {
    # Packet types
    AUTH            =>  3,  # Minecraft RCON login packet type
    AUTH_RESPONSE   =>  2,  # Server auth response
    AUTH_FAIL       => -1,  # Auth failure (password invalid)
    COMMAND         =>  2,  # Command packet type
    RESPONSE_VALUE  =>  0,  # Server response
};

class_type 'IP' => { class => 'IO::Socket::IP' };

has  host      => ( is => 'ro', default => 'localhost', isa => 'Str'        );
has  port      => ( is => 'ro', default => 25575,       isa => 'Int'        );
has  password  => ( is => 'ro', default => '',          isa => 'Str'        );
has  timeout   => ( is => 'rw', default => 30,          isa => 'Num'        );
has _select    => ( is => 'ro', default => sub { IO::Select->new }          );
has _socket    => ( is => 'rw', default => undef,       isa => 'Maybe[IP]'  );
has _next_id   => ( is => 'rw', default => 1,           isa => 'Int'        );

after _next_id => sub { $_[0]->{_next_id} = ($_[0]->{_next_id} + 1) % 2**31 };

sub connect {
    my ($s) = @_;

    return 1 if $s->connected;

    croak 'Password required' unless length $s->password;

    $s->_socket(IO::Socket::IP->new(
        PeerAddr => $s->host,
        PeerPort => $s->port,
        Proto    => 'tcp',
    )) or croak "Connection to @{[$s->host]}:@{[$s->port]} failed: $!";

    $s->_socket->autoflush(1);
    $s->_select->remove($s->_select->handles);
    $s->_select->add($s->_socket);

    my $id = $s->_next_id(1);
    $s->_send_encode(AUTH, $id, $s->password);
    my ($size,$res_id,$type,$payload) = $s->_read_decode;

    # Force a reconnect if we're about to error out
    $s->disconnect unless $type == AUTH_RESPONSE and $id == $res_id;

    croak "RCON authentication failed"           if $res_id == AUTH_FAIL;
    croak "Expected AUTH_RESPONSE(2), got $type" if   $type != AUTH_RESPONSE;
    croak "Expected ID $id, got $res_id"         if     $id != $res_id;
    croak "Non-blank payload <$payload>"         if  length $payload;

    return 1;
}

sub disconnect {
    my $s = shift;
    $s->_socket->shutdown(2) if $s->_socket and $s->_socket->connected;
    1;
}

sub connected  { $_[0]->_socket and $_[0]->_socket->connected }

sub command {
    my ($s, $command, $mode) = @_;

    croak 'Command required' unless length $command;
    $s->connect;

    my $id    = $s->_next_id;
    my $nonce = 16 + int rand(1 << 15 - 16); # Extra insurance
    $s->_send_encode(COMMAND, $id, $command);
    $s->_send_encode($nonce, $id, 'nonce');

    my $raw = '';
    while (1) {
        my ($size,$res_id,$type,$payload) = $s->_read_decode;
        if ($id != $res_id) {
            $s->disconnect;
            croak sprintf(
                'Desync. Expected %d (0x%04x), got %d (0x%04x). Disconnected.',
                $id, $id, $res_id, $res_id
            );
        }
        croak "size:$size id:$id got type $type, not RESPONSE_VALUE(0)"
            if $type != RESPONSE_VALUE;
        last if $payload eq sprintf 'Unknown request %x', $nonce;
        $raw .= $payload;
    }

    $raw =~ s!\r\n!\n!g; # \R would be nice, but requires 5.010

    Net::RCON::Minecraft::Response->new(raw => $raw, id => $id);
}

sub DESTROY { $_[0]->disconnect }

#
# Private methods -- Not for external use
#

# Grab a complete response from the Minecraft server and decode it,
# returning $id, $type, and $payload
sub _read_decode {
    my ($s) = @_;

    local $_ = $s->_read_with_timeout(4);

    my $size = unpack 'V';

    croak 'Packet too short. Size field = ' . $size . ' (10 is smallest)'
        if $size < 10;

    $_ = $s->_read_with_timeout($size);

    croak 'Server response missing terminator' unless s/\0\0$//;

    $size, unpack 'V!V(A*)';
}

# Read with timeout. Implemented with select. Guarantees either $len bytes are
# read, or we croak() trying. Returns the bytes read.
sub _read_with_timeout {
    my ($s, $len) = @_;

    my $ret = '';

    while ($len > length $ret) {
        if ($s->_select->can_read($s->timeout)) {
            my $buf = '';
            my $read = $s->_socket->sysread($buf, $len - length $ret);
            croak "Socket read error: $!" if not defined $read;
            $ret .= $buf;
        } else {
            $s->disconnect;
            croak "Server timeout. Got " .length($ret)."/".$len." bytes";
        }
    }

    $ret;
}

# Form and send a packet of the specified $type, $req_id and $payload
sub _send_encode {
    my ($s, $type, $id, $payload) = @_;
    $payload = "" unless defined $payload;
    my $data = pack('V!V' => $id, $type) . $payload . "\0\0";
    eval { $s->_socket->send(pack(V => length $data) . $data) };
    croak "Socket write failed: $@" if $@;

}

__PACKAGE__->meta->make_immutable();
