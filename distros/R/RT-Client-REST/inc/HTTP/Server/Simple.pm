#line 1
use strict;
use warnings;

package HTTP::Server::Simple;
use FileHandle;
use Socket;
use Carp;

use vars qw($VERSION $bad_request_doc);
$VERSION = '0.51';

#line 134

sub new {
    my ( $proto, $port, $family ) = @_;
    my $class = ref($proto) || $proto;

    if ( $class eq __PACKAGE__ ) {
        require HTTP::Server::Simple::CGI;
        return HTTP::Server::Simple::CGI->new( @_[ 1 .. $#_ ] );
    }

    my $self = {};
    bless( $self, $class );
    $self->port( $port || '8080' );
    $self->family( $family || AF_INET );

    return $self;
}


#line 159

sub lookup_localhost {
    my $self = shift;

    my $local_sockaddr = getsockname( $self->stdio_handle );
    my $local_family = sockaddr_family($local_sockaddr);

    my ($host_err,$local_host, undef) = Socket::getnameinfo($local_sockaddr,0);
    warn $host_err if ($host_err);
    $self->host( $local_host || "localhost");

    my ($addr_err,$local_addr,undef) = Socket::getnameinfo($local_sockaddr,Socket::NI_NUMERICHOST);
    warn $addr_err if ($addr_err);
    $self->{'local_addr'} = $local_addr
                            || (($local_family == AF_INET6) ? "::1" : "127.0.0.1");
}


#line 184

sub port {
    my $self = shift;
    $self->{'port'} = shift if (@_);
    return ( $self->{'port'} );

}

#line 203

sub family {
    my $self = shift;
    if (@_) {
        if ($_[0] == AF_INET || $_[0] == AF_INET6) {
            $self->{'family'} = shift;
        } else {
            $self->{'family'} = AF_INET;
        }
    }
    return ( $self->{'family'} );

}

#line 225

sub host {
    my $self = shift;
    $self->{'host'} = shift if (@_);
    return ( $self->{'host'} );

}

#line 239

sub background {
    my $self  = shift;
    my $child = fork;
    croak "Can't fork: $!" unless defined($child);
    return $child if $child;

    srand(); # after a fork, we need to reset the random seed
             # or we'll get the same numbers in both branches
    if ( $^O !~ /MSWin32/ ) {
        require POSIX;
        POSIX::setsid()
            or croak "Can't start a new session: $!";
    }
    $self->run(@_); # should never return
    exit;           # just to be sure
}

#line 265

my $server_class_id = 0;

use vars '$SERVER_SHOULD_RUN';
$SERVER_SHOULD_RUN = 1;

sub run {
    my $self   = shift;
    my $server = $self->net_server;

    local $SIG{CHLD} = 'IGNORE';    # reap child processes

    # $pkg is generated anew for each invocation to "run"
    # Just so we can use different net_server() implementations
    # in different runs.
    my $pkg = join '::', ref($self), "NetServer" . $server_class_id++;

    no strict 'refs';
    *{"$pkg\::process_request"} = $self->_process_request;

    if ($server) {
        require join( '/', split /::/, $server ) . '.pm';
        *{"$pkg\::ISA"} = [$server];

        # clear the environment before every request
        require HTTP::Server::Simple::CGI;
        *{"$pkg\::post_accept"} = sub {
            HTTP::Server::Simple::CGI::Environment->setup_environment;
            # $self->SUPER::post_accept uses the wrong super package
            $server->can('post_accept')->(@_);
        };
    }
    else {
        $self->setup_listener;
	$self->after_setup_listener();
        *{"$pkg\::run"} = $self->_default_run;
    }

    local $SIG{HUP} = sub { $SERVER_SHOULD_RUN = 0; };

    $pkg->run( port => $self->port, @_ );
}

#line 315

sub net_server {undef}

sub _default_run {
    my $self = shift;

    # Default "run" closure method for a stub, minimal Net::Server instance.
    return sub {
        my $pkg = shift;

        $self->print_banner;

        while ($SERVER_SHOULD_RUN) {
            local $SIG{PIPE} = 'IGNORE';    # If we don't ignore SIGPIPE, a
                 # client closing the connection before we
                 # finish sending will cause the server to exit
            while ( accept( my $remote = new FileHandle, HTTPDaemon ) ) {
                $self->stdio_handle($remote);
                $self->lookup_localhost() unless ($self->host);
                $self->accept_hook if $self->can("accept_hook");


                *STDIN  = $self->stdin_handle();
                *STDOUT = $self->stdout_handle();
                select STDOUT;   # required for HTTP::Server::Simple::Recorder
                                 # XXX TODO glasser: why?
                $pkg->process_request;
                close $remote;
            }
        }

        # Got here? Time to restart, due to SIGHUP
        $self->restart;
    };
}

#line 356

sub restart {
    my $self = shift;

    close HTTPDaemon;

    $SIG{CHLD} = 'DEFAULT';
    wait;

    ### if the standalone server was invoked with perl -I .. we will loose
    ### those include dirs upon re-exec. So add them to PERL5LIB, so they
    ### are available again for the exec'ed process --kane
    use Config;
    $ENV{PERL5LIB} .= join $Config{path_sep}, @INC;

    # Server simple
    # do the exec. if $0 is not executable, try running it with $^X.
    exec {$0}( ( ( -x $0 ) ? () : ($^X) ), $0, @ARGV );
}


sub _process_request {
    my $self = shift;

    # Create a callback closure that is invoked for each incoming request;
    # the $self above is bound into the closure.
    sub {

        $self->stdio_handle(*STDIN) unless $self->stdio_handle;

 # Default to unencoded, raw data out.
 # if you're sending utf8 and latin1 data mixed, you may need to override this
        binmode STDIN,  ':raw';
        binmode STDOUT, ':raw';

        # The ternary operator below is to protect against a crash caused by IE
        # Ported from Catalyst::Engine::HTTP (Originally by Jasper Krogh and Peter Edwards)
        # ( http://dev.catalyst.perl.org/changeset/5195, 5221 )
        
        my $remote_sockaddr = getpeername( $self->stdio_handle );
        my $family = sockaddr_family($remote_sockaddr);

        my ( $iport, $iaddr ) = $remote_sockaddr 
                                ? ( ($family == AF_INET6) ? sockaddr_in6($remote_sockaddr)
                                                          : sockaddr_in($remote_sockaddr) )
                                : (undef,undef);

        my $loopback = ($family == AF_INET6) ? "::1" : "127.0.0.1";
        my $peeraddr = $loopback;
        if ($iaddr) {
            my ($host_err,$addr, undef) = Socket::getnameinfo($remote_sockaddr,Socket::NI_NUMERICHOST);
            warn ($host_err) if $host_err;
            $peeraddr = $addr || $loopback;
        }

        
        my ( $method, $request_uri, $proto ) = $self->parse_request;
        
        unless ($self->valid_http_method($method) ) {
            $self->bad_request;
            return;
        }

        $proto ||= "HTTP/0.9";

        my ( $file, $query_string )
            = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?

        $self->setup(
            method       => $method,
            protocol     => $proto,
            query_string => ( defined($query_string) ? $query_string : '' ),
            request_uri  => $request_uri,
            path         => $file,
            localname    => $self->host,
            localport    => $self->port,
            peername     => $peeraddr,
            peeraddr     => $peeraddr,
            peerport     => $iport,
        );

        # HTTP/0.9 didn't have any headers (I think)
        if ( $proto =~ m{HTTP/(\d(\.\d)?)$} and $1 >= 1 ) {

            my $headers = $self->parse_headers
                or do { $self->bad_request; return };

            $self->headers($headers);

        }

        $self->post_setup_hook if $self->can("post_setup_hook");

        $self->handler;
    }
}

#line 463

sub stdio_handle {
    my $self = shift;
    $self->{'_stdio_handle'} = shift if (@_);
    return $self->{'_stdio_handle'};
}

#line 477

sub stdin_handle {
    my $self = shift;
    return $self->stdio_handle;
}

#line 490

sub stdout_handle {
    my $self = shift;
    return $self->stdio_handle;
}

#line 508

sub handler {
    my ($self) = @_;
    if ( ref($self) ne __PACKAGE__ ) {
        croak "do not call " . ref($self) . "::SUPER->handler";
    }
    else {
        croak "handler called out of context";
    }
}

#line 541

sub setup {
    my $self = shift;
    while ( my ( $item, $value ) = splice @_, 0, 2 ) {
        $self->$item($value) if $self->can($item);
    }
}

#line 575

sub headers {
    my $self    = shift;
    my $headers = shift;

    my $can_header = $self->can("header");
    return unless $can_header;
    while ( my ( $header, $value ) = splice @$headers, 0, 2 ) {
        $self->header( $header => $value );
    }
}

#line 624

sub print_banner {
    my $self = shift;

    print( ref($self) 
            . ": You can connect to your server at "
            . "http://localhost:"
            . $self->port
            . "/\n" );

}

#line 642

sub parse_request {
    my $self = shift;
    my $chunk;
    while ( sysread( STDIN, my $buff, 1 ) ) {
        last if $buff eq "\n";
        $chunk .= $buff;
    }
    defined($chunk) or return undef;
    $_ = $chunk;

    m/^(\w+)\s+(\S+)(?:\s+(\S+))?\r?$/;
    my $method   = $1 || '';
    my $uri      = $2 || '';
    my $protocol = $3 || '';

    # strip <scheme>://<host:port> out of HTTP/1.1 requests
    $uri =~ s{^\w+://[^/]+/}{/};

    return ( $method, $uri, $protocol );
}

#line 671

sub parse_headers {
    my $self = shift;

    my @headers;

    my $chunk = '';
    while ( sysread( STDIN, my $buff, 1 ) ) {
        if ( $buff eq "\n" ) {
            $chunk =~ s/[\r\l\n\s]+$//;
            if ( $chunk =~ /^([^()<>\@,;:\\"\/\[\]?={} \t]+):\s*(.*)/i ) {
                push @headers, $1 => $2;
            }
            last if ( $chunk =~ /^$/ );
            $chunk = '';
        }
        else { $chunk .= $buff }
    }

    return ( \@headers );
}

#line 698

sub setup_listener {
    my $self = shift;

    my $tcp = getprotobyname('tcp');
    my $sockaddr;
    socket( HTTPDaemon, $self->{'family'}, SOCK_STREAM, $tcp )
        or croak "socket: $!";
    setsockopt( HTTPDaemon, SOL_SOCKET, SO_REUSEADDR, pack( "l", 1 ) )
        or warn "setsockopt: $!";

    if ($self->host) { # Explicit listening address
        my ($err, @res) = Socket::getaddrinfo($self->host, $self->port, { family => $self->{'family'}, socktype => SOCK_STREAM } );
        warn "$err!"
          if ($err);
        # we're binding only to the first returned address in the requested family.
        while ($a = shift(@res)) {
            # Be certain on the address family.
            # TODO Accept AF_UNSPEC, reject SITE-LOCAL
            next unless ($self->{'family'} == $a->{'family'});

            # Use the first plausible address.
            $sockaddr = $a->{'addr'};
            last;
        }
    }
    else { # Use the wildcard address
        $sockaddr = ($self->{'family'} == AF_INET6)
                        ? sockaddr_in6($self->port(), Socket::IN6ADDR_ANY)
                        : sockaddr_in($self->port(), INADDR_ANY);
    }

    bind( HTTPDaemon, $sockaddr)
        or croak "bind to @{[$self->host||'*']}:@{[$self->port]}: $!";
    listen( HTTPDaemon, SOMAXCONN ) or croak "listen: $!";
}


#line 742

sub after_setup_listener {
}

#line 752

$bad_request_doc = join "", <DATA>;

sub bad_request {
    my $self = shift;

    print "HTTP/1.0 400 Bad request\r\n";    # probably OK by now
    print "Content-Type: text/html\r\nContent-Length: ",
        length($bad_request_doc), "\r\n\r\n", $bad_request_doc;
}

#line 771

sub valid_http_method {
    my $self   = shift;
    my $method = shift or return 0;
    return $method =~ /^(?:GET|POST|HEAD|PUT|PATCH|DELETE|OPTIONS)$/;
}

#line 805

1;

__DATA__
<html>
  <head>
    <title>Bad Request</title>
  </head>
  <body>
    <h1>Bad Request</h1>

    <p>Your browser sent a request which this web server could not
      grok.</p>
  </body>
</html>
