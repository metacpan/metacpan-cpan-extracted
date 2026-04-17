package Tailscale;
use strict;
use warnings;

our $VERSION = '0.01';

use FFI::Platypus 2.00;
use FFI::Platypus::Buffer qw(scalar_to_pointer buffer_to_scalar);
use Carp qw(croak);

use Tailscale::TcpListener;
use Tailscale::TcpStream;

# The Rust library requires this env var.
$ENV{TS_RS_EXPERIMENT} = "this_is_unstable_software";

my $ffi = FFI::Platypus->new(api => 2);

# Find the shared library.
my @lib_search = (
    $ENV{TS_LIB_PATH} ? "$ENV{TS_LIB_PATH}/libtailscalers.so" : (),
    "/home/ubuntu/src/github.com/tailscale/tailscale-rs/target/release/libtailscalers.so",
);
my ($lib_path) = grep { -f $_ } @lib_search;
croak "Cannot find libtailscalers.so; set TS_LIB_PATH" unless $lib_path;

$ffi->lib($lib_path);

# Opaque handle types
$ffi->type('opaque' => 'ts_device_t');
$ffi->type('opaque' => 'ts_tcp_listener_t');
$ffi->type('opaque' => 'ts_tcp_stream_t');
$ffi->type('opaque' => 'ts_udp_socket_t');

# Device lifecycle
$ffi->attach('ts_init'        => ['string', 'string']                           => 'ts_device_t');
$ffi->attach('ts_init_custom' => ['string', 'string', 'string', 'string']       => 'ts_device_t');
$ffi->attach('ts_deinit'      => ['ts_device_t']                                => 'void');

# IPv4 address: ts_ipv4_addr(dev, &mut in_addr_t) -> c_int
# in_addr_t is 4 bytes
$ffi->attach('ts_ipv4_addr' => ['ts_device_t', 'opaque'] => 'int');

# Socket address helpers
$ffi->attach('ts_parse_sockaddr'    => ['string', 'opaque'] => 'int');
$ffi->attach('ts_sockaddr_set_port' => ['opaque', 'uint16'] => 'int');

# TCP functions
$ffi->attach('ts_tcp_listen'       => ['ts_device_t', 'opaque']       => 'ts_tcp_listener_t');
$ffi->attach('ts_tcp_accept'       => ['ts_tcp_listener_t']           => 'ts_tcp_stream_t');
$ffi->attach('ts_tcp_connect'      => ['ts_device_t', 'opaque']       => 'ts_tcp_stream_t');
$ffi->attach('ts_tcp_send'         => ['ts_tcp_stream_t', 'opaque', 'size_t'] => 'int');
$ffi->attach('ts_tcp_recv'         => ['ts_tcp_stream_t', 'opaque', 'size_t'] => 'int');
$ffi->attach('ts_tcp_close'        => ['ts_tcp_stream_t']             => 'void');
$ffi->attach('ts_tcp_close_listener' => ['ts_tcp_listener_t']         => 'void');

# Internal constant: sockaddr struct size (32 bytes on x86_64)
use constant SOCKADDR_SIZE => 32;

# Internal helper: create a sockaddr from "ip:port" string
sub _parse_sockaddr {
    my ($addr_str) = @_;
    my $buf = "\0" x SOCKADDR_SIZE;
    my $ptr = scalar_to_pointer($buf);
    my $ret = ts_parse_sockaddr($addr_str, $ptr);
    croak "ts_parse_sockaddr failed for '$addr_str'" if $ret < 0;
    return ($buf, $ptr);
}

sub new {
    my ($class, %args) = @_;

    my $config_path = $args{config_path} // croak "config_path is required";
    my $auth_key    = $args{auth_key};
    my $control_url = $args{control_url};
    my $hostname    = $args{hostname};

    my $dev;
    if (defined $control_url || defined $hostname) {
        $dev = ts_init_custom($config_path, $auth_key, $control_url, $hostname);
    } else {
        $dev = ts_init($config_path, $auth_key);
    }
    croak "ts_init failed" unless $dev;

    return bless {
        _dev    => $dev,
        _closed => 0,
    }, $class;
}

sub ipv4_addr {
    my ($self) = @_;
    my $ipbuf = "\0" x 4;
    my $ipptr = scalar_to_pointer($ipbuf);
    my $ret = ts_ipv4_addr($self->{_dev}, $ipptr);
    croak "ts_ipv4_addr failed" if $ret < 0;
    my @octets = unpack("C4", $ipbuf);
    return join(".", @octets);
}

sub tcp_connect {
    my ($self, $addr_str) = @_;
    my ($buf, $ptr) = _parse_sockaddr($addr_str);
    my $stream = ts_tcp_connect($self->{_dev}, $ptr);
    croak "ts_tcp_connect failed for '$addr_str'" unless $stream;
    return Tailscale::TcpStream->_new($stream);
}

sub tcp_listen {
    my ($self, $port) = @_;
    my $ip = $self->ipv4_addr();
    my ($buf, $ptr) = _parse_sockaddr("$ip:$port");
    my $listener = ts_tcp_listen($self->{_dev}, $ptr);
    croak "ts_tcp_listen failed on $ip:$port" unless $listener;
    return Tailscale::TcpListener->_new($listener);
}

sub close {
    my ($self) = @_;
    return if $self->{_closed};
    $self->{_closed} = 1;
    ts_deinit($self->{_dev}) if $self->{_dev};
    $self->{_dev} = undef;
}

sub DESTROY {
    my ($self) = @_;
    local ($., $@, $!, $^E, $?);
    $self->close();
}

1;

__END__

=head1 NAME

Tailscale - Perl bindings for tailscale-rs

=head1 SYNOPSIS

    use Tailscale;

    my $ts = Tailscale->new(
        config_path => "state.json",
        auth_key    => "tskey-auth-...",
    );

    my $ip = $ts->ipv4_addr();    # e.g. "100.64.0.5"

    # Connect to a peer
    my $stream = $ts->tcp_connect("100.100.100.100:80");
    $stream->send_all("GET / HTTP/1.0\r\nHost: peer\r\n\r\n");
    my $data = $stream->recv(4096);

    # Listen for connections
    my $listener = $ts->tcp_listen(8080);
    my $conn = $listener->accept();

=head1 DESCRIPTION

Tailscale provides Perl bindings for
L<tailscale-rs|https://github.com/tailscale/tailscale-rs>, a Rust
implementation of Tailscale similar to Go's tsnet.  It lets you join a
Tailscale network directly from a Perl program with no C<tailscaled>
daemon required.

The module uses L<FFI::Platypus> to call the C FFI functions exported by the
C<libtailscalers.so> shared library built from tailscale-rs.

=head2 Finding the shared library

Set the C<TS_LIB_PATH> environment variable to the directory containing
C<libtailscalers.so>:

    export TS_LIB_PATH=/path/to/tailscale-rs/target/release

=head1 CONSTRUCTOR

=head2 new

    my $ts = Tailscale->new(%args);

Creates a new Tailscale node and connects it to the tailnet.  This call
blocks until the node is registered with the coordination server.

Arguments:

=over 4

=item config_path (required)

Path to a JSON file that stores the node's cryptographic identity.
Created automatically on first run.

=item auth_key

A Tailscale auth key (C<tskey-auth-...>) used to authorize the node.
May be omitted if the node is already authorized from a previous run.

=item hostname

The hostname this node requests on the tailnet.  Defaults to the OS
hostname.

=item control_url

URL of the Tailscale coordination server.  Defaults to the production
server.  Useful for testing with a custom control plane.

=back

=head1 METHODS

=head2 ipv4_addr

    my $ip = $ts->ipv4_addr();

Returns the node's Tailscale IPv4 address as a dotted-quad string
(e.g. C<"100.64.0.1">).  Blocks until an address is assigned.

=head2 tcp_connect

    my $stream = $ts->tcp_connect("100.64.0.2:80");

Opens a TCP connection to the given C<ip:port> on the tailnet.  Returns
a L<Tailscale::TcpStream> object.  Dies on failure.

=head2 tcp_listen

    my $listener = $ts->tcp_listen(8080);

Starts listening for TCP connections on the given port, bound to the
node's Tailscale IPv4 address.  Returns a L<Tailscale::TcpListener>
object.  Dies on failure.

=head2 close

    $ts->close();

Shuts down the Tailscale node and releases all resources.  Also called
automatically when the object is destroyed.

=head1 SEE ALSO

L<Tailscale::TcpStream>, L<Tailscale::TcpListener>,
L<Tailscale::HttpServer>, L<https://github.com/tailscale/tailscale-rs>

=head1 AUTHOR

Brad Fitzpatrick <brad@danga.com>

=head1 LICENSE

BSD-3-Clause

=cut
