package Pcore::AE::Patch;

use Pcore;
use Socket qw(AF_INET AF_UNIX SOCK_STREAM SOCK_DGRAM SOL_SOCKET SO_REUSEADDR);
use AnyEvent qw[];
use AnyEvent::Socket qw[];
use AnyEvent::Util qw[guard];

our $TTL            = 60;       # cache positive responses for 60 sec.
our $NEGATIVE_TTL   = 5;        # cache negative responses for 5 sec.
our $MAX_CACHE_SIZE = 10_000;

our $SOCKADDR_CACHE = {};

*AnyEvent::Socket::resolve_sockaddr_orig = \&AnyEvent::Socket::resolve_sockaddr;
*AnyEvent::Socket::_tcp_bind_orig        = \&AnyEvent::Socket::_tcp_bind;

# install hooks
{
    no warnings qw[redefine];

    *AnyEvent::Socket::resolve_sockaddr = \&resolve_sockaddr;
    *AnyEvent::Socket::_tcp_bind        = \&_tcp_bind;
    *AnyEvent::Socket::tcp_connect      = \&tcp_connect;
}

sub resolve_sockaddr ( $node, $service, $proto, $family, $type, $cb ) : prototype($$$$$$) {
    state $callback = {};

    if ( $node eq 'unix/' ) {

        # error
        return $cb->() if $family;

        # relative path treats as abstract UDS
        $service = "\x00$service" if substr( $service, 0, 1 ) ne '/';

        return $cb->( [ AF_UNIX, defined $type ? $type : SOCK_STREAM, 0, Socket::pack_sockaddr_un $service] );
    }

    my $cache_key = join q[-], map { $_ // q[] } @_[ 0 .. $#_ - 1 ];

    if ( exists $SOCKADDR_CACHE->{$cache_key} ) {
        if ( $SOCKADDR_CACHE->{$cache_key}->[0] > time ) {
            $cb->( $SOCKADDR_CACHE->{$cache_key}->[1]->@* );

            return;
        }
        else {
            delete $SOCKADDR_CACHE->{$cache_key};
        }
    }

    push $callback->{$cache_key}->@*, $cb;

    return if $callback->{$cache_key}->@* > 1;

    AnyEvent::Socket::resolve_sockaddr_orig(
        @_[ 0 .. $#_ - 1 ],
        sub (@) {

            # cleanup cache
            $SOCKADDR_CACHE = {} if keys $SOCKADDR_CACHE->%* > $MAX_CACHE_SIZE;

            # cache response
            $SOCKADDR_CACHE->{$cache_key} = [ time + ( @_ ? $TTL : $NEGATIVE_TTL ), \@_ ];

            # fire callbacks
            while ( my $cb = shift $callback->{$cache_key}->@* ) {
                $cb->(@_);
            }

            delete $callback->{$cache_key};

            return;
        }
    );

    return;
}

sub _tcp_bind ( $host, $service, $done, $prepare = undef ) : prototype($$$;$) {

    # hook for Linux abstract Unix Domain Sockets (UDS)
    if ( defined $host && $host eq 'unix/' && substr( $service, 0, 1 ) ne '/' ) {
        state $ipn_uds = pack 'S', AF_UNIX;

        # relative path treats as abstract UDS
        $service = "\x00$service";

        my %state;

        socket $state{fh}, AF_UNIX, SOCK_STREAM, 0 or die "tcp_server/socket: $!";

        bind $state{fh}, AnyEvent::Socket::pack_sockaddr $service, $ipn_uds or die "bind: $!";

        AnyEvent::fh_unblock $state{fh};

        my $len;

        $len = $prepare->( $state{fh}, AnyEvent::Socket::format_address $ipn_uds, $service ) if $prepare;

        $len ||= 128;

        listen $state{fh}, $len or die "listen: $!";

        $done->( \%state );

        return defined wantarray ? guard { %state = () } : ();
    }

    AnyEvent::Socket::_tcp_bind_orig(@_);

    return;
}

sub tcp_connect ( $host, $port, $connect, $prepare = undef ) : prototype($$$;$) {

    # see http://cr.yp.to/docs/connect.html for some tricky aspects
    # also http://advogato.org/article/672.html

    my %state = ( fh => undef );

    # name/service to type/sockaddr resolution
    AnyEvent::Socket::resolve_sockaddr $host, $port, 0, 0, undef, sub (@target) {
        $state{next} = sub {
            return unless exists $state{fh};

            my $errno = $!;

            my $target = shift @target or return AE::postpone {
                return unless exists $state{fh};

                %state = ();

                $! = $errno;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

                $connect->();

                return;
            };

            my ( $domain, $type, $proto, $sockaddr ) = $target->@*;

            # socket creation
            socket $state{fh}, $domain, $type, $proto or return $state{next}();

            AnyEvent::fh_unblock $state{fh};

            my $timeout = eval { $prepare && $prepare->( $state{fh} ) };

            if ($@) {
                $state{next}->();

                return;
            }

            $timeout ||= 30 if AnyEvent::WIN32;

            if ($timeout) {
                $state{to} = AE::timer $timeout, 0, sub {
                    $! = Errno::ETIMEDOUT;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

                    $state{next}();

                    return;
                };
            }

            # now connect
            if (connect( $state{fh}, $sockaddr )
                || ($! == Errno::EINPROGRESS    # POSIX
                    || $! == Errno::EWOULDBLOCK

                    # WSAEINPROGRESS intentionally not checked - it means something else entirely
                    || $! == AnyEvent::Util::WSAEINVAL    # not convinced, but doesn't hurt
                    || $! == AnyEvent::Util::WSAEWOULDBLOCK
                )
              )
            {
                $state{ww} = AE::io $state{fh}, 1, sub {

                    # we are connected, or maybe there was an error
                    if ( my $sin = getpeername $state{fh} ) {
                        my ( $port, $host ) = AnyEvent::Socket::unpack_sockaddr $sin;

                        delete $state{ww};
                        delete $state{to};

                        my $guard = AnyEvent::Socket::guard { %state = () };

                        $connect->(
                            delete $state{fh},
                            AnyEvent::Socket::format_address $host,
                            $port,
                            sub {
                                $guard->cancel;

                                $state{next}->();

                                return;
                            }
                        );
                    }
                    else {
                        if ( $! == Errno::ENOTCONN ) {

                            # dummy read to fetch real error code if !cygwin
                            sysread $state{fh}, my $buf, 1 or 1;

                            # cygwin 1.5 continously reports "ready' but never delivers
                            # an error with getpeername or sysread.
                            # cygwin 1.7 only reports readyness *once*, but is otherwise
                            # the same, which is actually more broken.
                            # Work around both by using unportable SO_ERROR for cygwin.
                            $! = ( unpack "l", getsockopt $state{fh}, Socket::SOL_SOCKET(), Socket::SO_ERROR() ) || Errno::EAGAIN if AnyEvent::CYGWIN && $! == Errno::EAGAIN;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]
                        }

                        return if $! == Errno::EAGAIN;                                                                                                                           # skip spurious wake-ups

                        delete $state{ww};

                        delete $state{to};

                        $state{next}->();
                    }
                };
            }
            else {
                $state{next}->();
            }
        };

        $! = Errno::ENXIO;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

        $state{next}->();
    };

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 16, 23               | Variables::ProtectPrivateVars - Private variable used                                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 27                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 112                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 117                  | Subroutines::ProhibitExcessComplexity - Subroutine "tcp_connect" with high complexity score (24)               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 216                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 36, 89               | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::AE::Patch

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
