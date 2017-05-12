use strict;
use warnings;

package Net::Server::Proto::Coro;
use base qw/Coro::Socket/;

sub new_from_fh {
    my $class = shift;
    my $fh    = shift or return;
    my $self  = do { local *Coro::Handle };

    tie *$self, 'Net::Server::Proto::Coro::FH', fh => $fh, @_;

    bless \$self, ref $class ? ref $class : $class;
}

sub NS_host   { tied( *${+shift} )->[0]->NS_host(@_) };
sub NS_port   { tied( *${+shift} )->[0]->NS_port(@_) };
sub NS_proto  { tied( *${+shift} )->[0]->NS_proto(@_) };
sub NS_ipv    { tied( *${+shift} )->[0]->NS_ipv(@_) };
sub sockport  { tied( *${+shift} )->[0]->sockport(@_) };
sub connect   { tied( *${+shift} )->[0]->connect(@_) };
sub reconnect { tied( *${+shift} )->[0]->reconnect(@_) };

sub accept {
    my $self = shift;

    my $socket = tied( *${$self} )->[0];
    while (1) {
        $self->readable or return;
        my ( $fh, $peername ) = $socket->accept;
        if ($peername) {
            my $socket = $self->new_from_fh(
                $fh,
                forward_class => tied( *${$self} )->[7],
                expects_ssl   => tied( *${$self} )->[9],
                server_cert   => tied( *${$self} )->[12],
                server_key    => tied( *${$self} )->[13],
            );
            return wantarray ? ( $socket, $peername ) : $socket;
        }

        return unless $!{EAGAIN};
    }
}

sub expects_ssl {
    my $self = tied *${ $_[0] };
    $self->[9] = shift if @_;
    return $self->[9];
}

sub is_ssl {
    my $self = tied *${ $_[0] };
    return $self->[10] ? 1 : 0;
}

sub start_SSL   { Net::Server::Proto::Coro::FH::start_SSL( tied *${+shift}, @_) }
sub read        { Net::Server::Proto::Coro::FH::READ     ( tied *${$_[0]}, $_[1], $_[2], $_[3]) }
sub sysread     { Net::Server::Proto::Coro::FH::READ     ( tied *${$_[0]}, $_[1], $_[2], $_[3]) }
sub syswrite    { Net::Server::Proto::Coro::FH::WRITE    ( tied *${$_[0]}, $_[1], $_[2], $_[3]) }
sub print       { Net::Server::Proto::Coro::FH::WRITE    ( tied *${+shift}, join "", @_) }
sub printf      { Net::Server::Proto::Coro::FH::PRINTF   ( tied *${+shift}, @_) }
sub fileno      { Net::Server::Proto::Coro::FH::FILENO   ( tied *${$_[0]}) }
sub close       { Net::Server::Proto::Coro::FH::CLOSE    ( tied *${$_[0]}) }

package Net::Server::Proto::Coro::FH;
use base qw/Coro::Handle::FH/;

our $HAS_SSL;

BEGIN {
    $HAS_SSL = 0;
    if (eval {require Net::SSLeay; 1} ) {
        $HAS_SSL = 1;
        Net::SSLeay::load_error_strings();
        Net::SSLeay::SSLeay_add_ssl_algorithms();
        Net::SSLeay::randomize();
    }
}

sub TIEHANDLE {
    my ( $class, %arg ) = @_;

    die "Net::SSLeay is required for SSL sockets"
        if $arg{expects_ssl} and not $HAS_SSL;

    my $self = $class->SUPER::TIEHANDLE(%arg);
    $self->[9]  = $arg{expects_ssl};
    $self->[10] = undef; # SSLeay object
    $self->[11] = undef; # SSL context object
    $self->[12] = $arg{server_cert};
    $self->[13] = $arg{server_key};

    return $self;
}

sub READ_UNTIL {
    my $sub   = pop;
    my $tries = 0;
    while () {

        # first deplete the read buffer
        if ( length $_[0][3] ) {
            my $v = $sub->(@_);
            return $v if defined $v;
        }

        return unless Coro::Handle::FH::readable( $_[0] );
        $_[0]->force_close and return unless $_[0][10];
        my $r    = Net::SSLeay::read( $_[0][10] );
        my $errs = Net::SSLeay::print_errs('SSL_read');
        warn "SSL Read error: $errs\n" if $errs;

        if ( defined $r and length $r ) {
            $_[0][3] .= $r;
            $tries = 0;
        } else {
            $_[0]->force_close and return if ++$tries >= 100;
        }
    }
}

sub READ {

    return Coro::Handle::FH::READ(@_) unless $_[0][9];
    $_[0]->force_close and return unless $_[0][10] or $_[0]->start_SSL;

    my $len  = $_[2];
    my $ofs  = $_[3];
    my $stop = sub {
        my $l = length $_[0][3];
        if ( $l <= $len ) {
            substr( $_[1], $ofs ) = $_[0][3];
            $_[0][3] = "";
            return $l;
        } else {
            substr( $_[1], $ofs ) = substr( $_[0][3], 0, $len );
            substr( $_[0][3], 0, $len ) = "";
            return $len;
        }
        return undef;
    };

    READ_UNTIL( @_, $stop );
}

sub READLINE {
    return Coro::Handle::FH::READLINE(@_) unless $_[0][9];
    $_[0]->force_close and return unless $_[0][10] or $_[0]->start_SSL;

    my $irs = $_[1] || $/;
    my $stop = sub {
        my $pos = index $_[0][3], $irs;
        if ( $pos >= 0 ) {
            $pos += length $irs;
            my $res = substr $_[0][3], 0, $pos;
            substr( $_[0][3], 0, $pos ) = "";
            return $res;
        }
        return undef;
    };

    READ_UNTIL( @_, $stop );
}

sub WRITE {
    return Coro::Handle::FH::WRITE(@_) unless $_[0][9];
    $_[0]->force_close and return unless $_[0][10] or $_[0]->start_SSL;

    my $len = defined $_[2] ? $_[2] : length $_[1];
    my $ofs = $_[3] || 0;
    my $res = 0;

    return unless Coro::Handle::FH::writable( $_[0] );
    while (1) {
        my $str = substr( $_[1], $ofs, $len );
        $_[0]->force_close and return unless $_[0][10];
        my $r = Net::SSLeay::write( $_[0][10], $str );

        if ( $r < 0 ) {
            my $err = Net::SSLeay::get_error( $_[0][10], $r );

            if ( $err == Net::SSLeay::ERROR_WANT_READ() ) {
                $_[0]->force_close and return unless Coro::Handle::FH::readable( $_[0] );
            } elsif ( $err == Net::SSLeay::ERROR_WANT_WRITE() ) {
                $_[0]->force_close and return unless Coro::Handle::FH::writable( $_[0] );
            } else {
                my $errstr = Net::SSLeay::ERR_error_string($err);
                warn "SSL write error: $err, $errstr\n";
                $_[0]->force_close;
                return undef;
            }
        } else {
            $len -= $r;
            $ofs += $r;
            $res += $r;
            return $res unless $len;
            $_[0]->force_close and return unless Coro::Handle::FH::writable( $_[0] );
        }
    }
}

sub FILENO {
   fileno $_[0][0]
}

use constant SSL_RECEIVED_SHUTDOWN => 2;

sub CLOSE {
    return unless @{ $_[0] } and $_[0][0];
    if ( $_[0][10] ) {
        my $status = Net::SSLeay::get_shutdown( $_[0][10] );
        unless ( $status == SSL_RECEIVED_SHUTDOWN ) {
            local $SIG{PIPE} = sub { };
            for my $try ( 1, 2 ) {
                my $rv = Net::SSLeay::shutdown( $_[0][10] );
                last unless $rv >= 0;
            }
        }
        $_[0]->ssl_free;
    }
    my $handle = $_[0][0];
    Coro::Handle::FH::cleanup(@_);
    shutdown( $handle, 2 );
    return 1;
}

sub ssl_free {
    Net::SSLeay::free( $_[0][10] );
    $_[0][10] = undef;
    $_[0][11] = undef;
}

sub force_close {
    $_[0]->ssl_free if $_[0][10];
    $_[0]->CLOSE;
    return 1;
}

use constant SSL_MODE_ENABLE_PARTIAL_WRITE       => 1;
use constant SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER => 2;

use vars qw/$CONTEXT/;

sub start_SSL {
    die "Net::SSLeay is required for SSL sockets"
        if not $HAS_SSL;

    my $ctx;
    $_[0][9] = 1;
    my $server_cert = $_[1] || $_[0][12] || "certs/server-cert.pem";
    my $server_key  = $_[2] || $_[0][13] || "certs/server-key.pem";
    die "Can't read certificates ($server_cert and $server_key)\n"
        unless -r $server_cert and -r $server_key;

    unless ($CONTEXT) {
        $ctx = $CONTEXT = Net::SSLeay::CTX_new();
        Net::SSLeay::CTX_set_options( $ctx, Net::SSLeay::OP_ALL() );
        Net::SSLeay::CTX_set_mode( $ctx,
            SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER
                | SSL_MODE_ENABLE_PARTIAL_WRITE );
        Net::SSLeay::CTX_use_PrivateKey_file( $ctx, $server_key,
            Net::SSLeay::FILETYPE_PEM() );
        Net::SSLeay::CTX_use_certificate_chain_file( $ctx,
            $server_cert );
    }
    $ctx = $CONTEXT;
    $_[0][11] = $ctx;

    $_[0][10] = Net::SSLeay::new($ctx);
    Net::SSLeay::set_fd( $_[0][10], fileno( $_[0][0] ) );

    # Purge any remaining contents of the read buffer.  This prevents
    # plaintext injection attacks wherein attackers could cause
    # nominally SSL-only commands to be executed by appending them to
    # the end of a STARTTLS.
    if (length $_[0][3]) {
        warn "SSL accept with pending plaintext (attempted CVE-2011-0411 attack?)\n";
        $_[0][3] = "";
    }

    while (1) {
        my $rv = Net::SSLeay::accept($_[0][10]);
        if ( $rv < 0 ) {
            my $err = Net::SSLeay::get_error( $_[0][10], $rv );
            if ( $err == Net::SSLeay::ERROR_WANT_READ() ) {
                $_[0]->force_close and return unless Coro::Handle::FH::readable( $_[0] );
            } elsif ( $err == Net::SSLeay::ERROR_WANT_WRITE() ) {
                $_[0]->force_close and return unless Coro::Handle::FH::writable( $_[0] );
            } else {
                my $errstr = Net::SSLeay::ERR_error_string($err);
                warn "SSL accept error: $err, $errstr\n";
                $_[0]->force_close;
                return;
            }
        } elsif ( $rv == 0 ) {
            $_[0]->force_close;
            return;
        } else {
            return $_[0];
        }
    }
}

1;
