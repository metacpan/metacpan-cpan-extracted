package MyServer;

use strict;
use warnings;
use autodie;

use Test::More;

use File::Temp;
use Time::HiRes;
use Socket;

our $CRLF = "\x0d\x0a";
our $HEAD_START = join(
    $CRLF,
    'HTTP/1.0 200 OK',
    'X-test: Yay',
    'Content-type: text/plain',
    q<>
);

our $BIGGIE = ('x' x 512);

sub new {
    my ($class) = @_;

    my $srv = _create_socket();

    my $end_fh = File::Temp::tempfile();

    my ($port) = Socket::unpack_sockaddr_in(getsockname $srv);

    diag "SERVER PORT: $port";

    my $pid = fork or do {
        my $ok = eval {
            CustomServer::HTTP::run($srv, $end_fh);
            1;
        };

        warn if !$ok;
        exit( $ok ? 0 : 1 );
    };

    diag "SERVER PID: $pid";

    close $srv;

    return bless {
        pid => $pid,
        port => $port,
        end_fh => $end_fh
    }, $class;
}

sub finish {
    $_[0]->{'finished'} ||= do {
        my $pid = $_[0]->{'pid'};
        diag "FINISHING SERVER: PID $pid (from PID $$)";

        syswrite $_[0]->{'end_fh'}, 'x';

        waitpid $pid, 0;

        diag "REAPED SERVER: PID $pid (from PID $$)";

        1;
    };

    return;
}

sub _create_socket {
    socket my $srv, Socket::AF_INET, Socket::SOCK_STREAM, 0;

    bind $srv, Socket::pack_sockaddr_in(0, "\x7f\0\0\1");

    listen $srv, 10;

    return $srv;
}

sub port { $_[0]->{'port'} }

sub DESTROY {
    my ($self) = @_;

    $self->finish();
}

#----------------------------------------------------------------------
package CustomServer::HTTP;

use autodie;

use Test::More;

my $DIAG = 0;

sub _time_out_readable {
    my ($socket, $timeout) = @_;

    my $rin = q<>;
    vec( $rin, fileno($socket), 1 ) = 1;

    my $got = select my $rout = $rin, undef, undef, $timeout;

    if ($got < 0) {
        warn "select(): $!";
        $got = 0;
    }

    return $got;
}

# A blocking, non-forking server.
# Written this way to achieve maximum simplicity.
sub run {
    my ($socket, $end_fh) = @_;

    $SIG{'PIPE'} = 'IGNORE';

  ACCEPT:
    while (!-s $end_fh) {
        next if !_time_out_readable($socket, 0.1);

        _DIAG("Accepting connection …");
        accept( my $cln, $socket );
        _DIAG("Received connection; reading …");

        my $buf = q<>;
        while (-1 == index($buf, "\x0d\x0a\x0d\x0a")) {
            sysread( $cln, $buf, 512, length $buf ) or do {
                _DIAG("Connection closed prematurely.");
                next ACCEPT;
            };
        }

        _DIAG("Received headers");

        $buf =~ m<GET \s+ (\S+)>x or die "Bad request: $buf";
        my $uri_path = $1;

        _DIAG("URI: $uri_path");

        diag "connection failed: $@" if !eval {
            syswrite $cln, $MyServer::HEAD_START;
            syswrite $cln, "X-URI: $uri_path$MyServer::CRLF";
            syswrite $cln, $MyServer::CRLF;

            syswrite $cln, ( $uri_path eq '/biggie' ? $MyServer::BIGGIE : $uri_path );

            # Proper TCP shutdown.
            shutdown $cln, 0;
            1 while sysread $cln, my $throwaway, 65536;

            1;
        };
    }

    diag "Server ($$) received request to shut down";
}

sub _DIAG {
    diag "Server (PID $$): " . shift() if $DIAG;
}

1;
