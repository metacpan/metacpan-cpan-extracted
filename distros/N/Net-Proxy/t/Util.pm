use strict;
use warnings;
use IO::Socket::INET;

# return sockets connected to free ports
# we can use sockport() to learn the port values
# and close() to close the socket just before reopening it
sub find_free_ports {
    my $n = shift;
    my @socks;

    for ( 1 .. $n ) {
        my $sock = listen_on_port(0);
        if ($sock) {
            push @socks, $sock;
        }
    }
    my @ports = map { $_->sockport() } @socks;
    diag "ports: @ports";

    # close the sockets and return the ports
    $_->close() for @socks;
    return @ports;
}

# return a socket connected to port $port on localhost
sub connect_to_port {
    my ($port, %opts) = @_;
    return IO::Socket::INET->new(
        PeerAddr => 'localhost',
        PeerPort => $port,
        Proto    => 'tcp',
        %opts
    );
}

# return a socket listening on $port on localhost
sub listen_on_port {
    my ($port) = @_;
    return IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => 'localhost',
        LocalPort => $port,
        Proto     => 'tcp',
    );
}

# fork a proxy with the given args
sub fork_proxy {
    my ( $args, $count ) = @_;

    my $pid = fork;
    return if !defined $pid;

    if ( $pid == 0 ) {

        # the child process runs the proxy
        my $proxy = Net::Proxy->new($args);
        $proxy->register();

        Net::Proxy->set_verbosity( $ENV{NET_PROXY_VERBOSITY} || 0 );
        Net::Proxy->mainloop( $count                         || 1 );
        exit;
    }

    return $pid;
}

# compute a seed and show it
use POSIX qw( INT_MAX );

sub init_rand {
    my $seed = @_ ? $_[0] : int rand INT_MAX;
    diag "Random seed $seed";
    srand $seed;
}

# randomly exchange (or not) a pair
sub random_swap {
    my ( $first, $second ) = @_;
    return rand > 0.5 ? ( $first, $second ) : ( $second, $first );
}

#
# Testing functions
#
use Test::Builder;
my $Tester = Test::Builder->new();

# skip but fail
sub skip_fail {
    my ($why, $how_many) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    for( 1 .. $how_many ) {
        $Tester->ok( 0, $why );
    }
    no warnings;
    last SKIP;
}

use IO::Select;
use Test::More;
sub is_closed {
    my ($sock, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $name ||= "$sock";
    my $select = IO::Select->new( $sock );
    my @read   =  $select->can_read();
    if( @read ) {
        my $buf;
        my $read = $read[0]->sysread( $buf, 4096 );
        $Tester->is_eq( $read, 0, "$name closed" );
    }
}

1;
