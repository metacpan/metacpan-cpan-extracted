package Pcore::API::ProxyPool::Proxy;

use Pcore -class;
use Pcore::API::ProxyPool::Proxy::Removed;
use Pcore::AE::Handle2 qw[:ALL];

extends qw[Pcore::Util::URI];

has source => ( is => 'ro', isa => ConsumerOf ['Pcore::API::ProxyPool::Source'], required => 1, weak_ref => 1 );
has pool   => ( is => 'ro', isa => ConsumerOf ['Pcore::API::ProxyPool'],         required => 1, weak_ref => 1 );

has id => ( is => 'lazy', isa => Str, init_arg => undef );

has connect_error_timeout => ( is => 'lazy', isa => PositiveInt );          # timout for enable proxy after connect error
has max_connect_errors    => ( is => 'lazy', isa => PositiveInt );          # max. connect errors, after which proxy will be removed from pool
has ban_timeout           => ( is => 'lazy', isa => PositiveOrZeroInt );    # default proxy ban timeout
has max_threads           => ( is => 'lazy', isa => PositiveOrZeroInt );    # max. allowed concurrent threads via this proxy

has removed       => ( is => 'ro', default => 0, init_arg => undef );       # proxy is removed
has connect_error => ( is => 'ro', default => 0, init_arg => undef );       # proxy has connection error

has test_connection => ( is => 'lazy', isa => HashRef, default => sub { {} }, clearer => 1, init_arg => undef );    # tested connections cache
has test_scheme     => ( is => 'lazy', isa => HashRef, default => sub { {} }, clearer => 1, init_arg => undef );    # tested schemes cache

has connect_error_time => ( is => 'ro', isa => Int, default => 0, init_arg => undef );                              # next connect_error release time
has connect_errors     => ( is => 'ro', isa => Int, default => 0, init_arg => undef );                              # connect errors counter
has threads            => ( is => 'ro', isa => Int, default => 0, init_arg => undef );                              # current threads number
has total_threads      => ( is => 'ro', isa => Int, default => 0, init_arg => undef );                              # total connections was made through this proxy

has _waiting_callbacks => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );
has _ban_list          => ( is => 'ro', isa => HashRef,  default => sub { {} }, init_arg => undef );

has is_proxy_pool => ( is => 'ro', default => 0, init_arg => undef );

around new => sub ( $orig, $self, $uri, $source ) {
    my $uri_args = $self->_parse_uri_string( $uri, 1 );

    return if !$uri_args->{host};

    return if !$uri_args->{port};

    if ( ( my $idx = index $uri_args->{port}, q[:] ) != -1 ) {
        $uri_args->{userinfo} = substr $uri_args->{port}, $idx, length $uri_args->{port}, q[];

        substr $uri_args->{userinfo}, 0, 1, q[];
    }

    $uri_args->{source} = $source;

    $uri_args->{pool} = $source->pool;

    $self->_prepare_uri_args( $uri_args, {} );

    return $self->$orig($uri_args);
};

our $PROXY_TEST_TIMEOUT = 10;

our $CHECK_SCHEME = {
    tcp   => [ [ $PROXY_TYPE_CONNECT, $PROXY_TYPE_SOCKS4, $PROXY_TYPE_SOCKS5 ] ],                                                                       # default scheme
    udp   => [ [$PROXY_TYPE_SOCKS5] ],
    http  => [ [ $PROXY_TYPE_CONNECT, $PROXY_TYPE_SOCKS4, $PROXY_TYPE_SOCKS5, $PROXY_TYPE_HTTP ], [ 'www.google.com', 80 ], \&_test_scheme_httpx, ],
    https => [ [ $PROXY_TYPE_CONNECT, $PROXY_TYPE_SOCKS4, $PROXY_TYPE_SOCKS5, $PROXY_TYPE_HTTP ], [ 'www.google.com', 443 ], \&_test_scheme_httpx, ],
    whois => [ [ $PROXY_TYPE_CONNECT, $PROXY_TYPE_SOCKS4, $PROXY_TYPE_SOCKS5 ], [ 'whois.iana.org', 43 ], \&_test_scheme_whois, ],
};

# BUILDERS
sub _build_id ($self) {
    state $id = 0;

    return ++$id;
}

sub _build_connect_error_timeout ($self) {
    return $self->source->connect_error_timeout;
}

sub _build_max_connect_errors ($self) {
    return $self->source->max_connect_errors;
}

sub _build_ban_timeout ($self) {
    return $self->pool->ban_timeout;
}

sub _build_max_threads ($self) {
    return $self->source->max_threads_proxy;
}

sub remove ($self) {
    $self->pool->storage->remove_proxy($self);

    delete $self->pool->list->{ $self->hostport };

    $self->_on_status_change;

    $self->%* = (
        removed       => 1,
        connect_error => 1,
    );

    bless $self, 'Pcore::API::ProxyPool::Proxy::Removed';

    return;
}

sub ban ( $self, $ban_id, $timeout = undef ) {
    return if $self->source->is_multiproxy;

    $self->{_ban_list}->{$ban_id} = time + ( $timeout || $self->ban_timeout );

    $self->pool->storage->ban_proxy( $self, $ban_id, $self->{_ban_list}->{$ban_id} );

    return;
}

sub is_banned ( $self, $ban_id ) {
    return if !defined $ban_id || !exists $self->{_ban_list}->{$ban_id};

    return $self->{_ban_list}->{$ban_id} <= time ? 0 : 1;
}

# CONNECT METHODS
sub _set_connect_error ($self) {
    return if $self->{connect_error};

    # set "connect_error" flag
    $self->{connect_error} = 1;

    # flush caches
    $self->clear_test_connection;

    $self->clear_test_scheme;

    $self->{connect_errors}++;

    if ( $self->{connect_errors} >= $self->max_connect_errors ) {
        $self->remove;
    }
    else {
        $self->{connect_error_time} = time + $self->connect_error_timeout;

        $self->pool->storage->set_connect_error($self);

        $self->_on_status_change;
    }

    return;
}

sub _start_thread ($self) {
    $self->{threads}++;

    $self->{total_threads}++;

    $self->{source}->start_thread;

    $self->pool->storage->update_weight($self);

    return;
}

sub _finish_thread ($self) {
    $self->{threads}--;

    $self->{source}->finish_thread;

    $self->pool->storage->update_weight($self);

    $self->_on_status_change;

    return;
}

sub weight ($self) {

    # NOTE
    # weight should be >= 0;
    # weight == 0 - disable proxy;
    # weight should be integer;
    # proxy with minimal weight will be selected;

    # the following vars can be used to calculate weight:
    # $self->{source}->{threads}
    # $self->{source}->{total_threads}
    # $self->{source}->max_threads_source
    # $self->max_threads
    # $self->{threads}
    # $self->{total_threads}

    # disable proxy, if proxy has max. threads limit and this limit is exceeded
    return 0 if $self->max_threads && $self->{threads} >= $self->max_threads;

    # simple round-robin
    return 1 + $self->{threads} + $self->{total_threads};
}

# CONNECT
sub get_slot ( $self, $connect, @ ) {
    my $cb = $_[-1];

    my %args = (
        wait   => 0,    # wait for proxy slot
        ban_id => 0,    # check for ban
        splice @_, 2, -1,
    );

    if ( $self->{connect_error} ) {

        # proxy has connection error, return immediately
        $cb->( $self, 0 );
    }
    else {
        $connect = Pcore::AE::Handle2::get_connect($connect);

        my $cached_proxy_type = $self->{test_connection}->{ $connect->[3] };

        if ( defined $cached_proxy_type && $cached_proxy_type == 0 ) {

            # proxy is not available for this connection, no need to get slot
            # return immediately
            $cb->( $self, 0 );

            return;
        }

        $self->_wait_slot(
            \%args,
            sub ( $self, $thread_started ) {    # $self can be undef here - this means that proxy is not available
                my $on_finish = sub ( $self, $proxy_type ) {

                    # finish thread here if proxy is not available for this connection
                    # because connection handle will not be created
                    $self->_finish_thread if !$proxy_type && $thread_started;

                    $cb->( $self, $proxy_type );

                    return;
                };

                if ( !$thread_started ) {

                    # proxy is not availalble
                    $on_finish->( $self, 0 );
                }
                elsif ( defined( my $proxy_type = $self->{test_connection}->{ $connect->[3] } ) ) {

                    # proxy already checked, return cached result immediately
                    $on_finish->( $self, $proxy_type );
                }
                else {

                    # run proxy test for connection
                    $self->_check( $connect, $on_finish );
                }

                return;
            }
        );
    }

    return;
}

sub _can_connect ( $self, $ban_id = undef ) {
    return if !$self->{source}->can_connect;

    return if $self->max_threads && $self->{threads} >= $self->max_threads;

    return if $self->is_banned($ban_id);

    return 1;
}

# TODO how to process source unlock???
sub _wait_slot ( $self, $args, $cb ) {
    if ( $self->_can_connect( $args->{ban_id} ) ) {

        # slot is available
        $self->_start_thread;

        $cb->( $self, 1 );
    }
    elsif ( !$args->{wait} ) {

        # connect slot is not available right now and we do not want to wait
        $cb->( $self, 0 );
    }
    else {
        # connect slot is not available right now, cache callback and wait
        push $self->_waiting_callbacks->@*, [ $cb, $args->{ban_id} ];
    }

    return;
}

# called on proxy connect error or when proxy thread is finished
# TODO how to process source unlock???
sub _on_status_change ($self) {
    if ( $self->{connect_error} ) {
        while ( my $wait_slot_cb = shift $self->_waiting_callbacks->@* ) {
            $wait_slot_cb->[0]->( $self, 0 );
        }
    }
    else {
        return if !$self->{_waiting_callbacks}->@*;

        my $i = 0;

        while (1) {
            my $wait_slot_cb = $self->{_waiting_callbacks}->[$i];

            if ( $self->_can_connect( $wait_slot_cb->[1] ) ) {
                splice $self->{_waiting_callbacks}->@*, $i, 1;

                $self->_start_thread;

                $wait_slot_cb->[0]->( $self, 1 );
            }
            else {
                last if !$wait_slot_cb->[1];    # can't connect to the proxy due to the threads limit, no sense to continue cycle

                $i++;
            }

            last if $i > $self->{_waiting_callbacks}->$#*;
        }

        $self->pool->_on_status_change if $self->connect;
    }

    return;
}

# CHECK PROXY
sub _check ( $self, $connect, $cb ) {
    state $callback = {};

    # cache callback
    my $cache_key = $self->id . q[-] . $connect->[3];

    push $callback->{$cache_key}->@*, $cb;

    return if $callback->{$cache_key}->@* > 1;

    my @types = $CHECK_SCHEME->{ $connect->[2] }->[0]->@*;

    my $test = sub ($proxy_type) {
        if ( !$self->{connect_error} && !$proxy_type && ( my $test_proxy_type = shift @types ) ) {
            if ( $test_proxy_type == $PROXY_TYPE_HTTP ) {
                $self->_check_http( $test_proxy_type, $connect, __SUB__ );
            }
            else {
                $self->_check_tunnel( $test_proxy_type, $connect, __SUB__ );
            }
        }
        else {
            # cache test result only if no connect error
            if ( !$self->{connect_error} ) {

                # reset connect errors counter
                $self->{connect_errors} = 0;

                # cache connection test result
                $self->{test_connection}->{ $connect->[3] } = $proxy_type;

                $self->pool->storage->set_connection_test_results( $self, $connect->[3], $proxy_type );
            }

            # call cached callbacks
            while ( my $cb = shift $callback->{$cache_key}->@* ) {
                $cb->( $self, $proxy_type );
            }

            delete $callback->{$cache_key};
        }
    };

    # run tests
    $test->(0);

    return;
}

sub _check_http ( $self, $proxy_type, $connect, $cb ) {
    $self->_test_scheme(
        $connect->[2],
        $proxy_type,
        sub ($scheme_ok) {
            if ($scheme_ok) {    # scheme test failed
                $cb->($proxy_type);
            }
            else {               # scheme test passed
                $cb->(0);
            }

            return;
        }
    );

    return;
}

sub _check_tunnel ( $self, $proxy_type, $connect, $cb ) {
    $self->_test_scheme(
        $connect->[2],
        $proxy_type,
        sub ($scheme_ok) {
            if ( !$scheme_ok ) {    # scheme test failed
                $cb->(0);
            }
            else {                  # scheme test passed

                # scheme was really tested
                # but connect port is differ from default scheme test port
                # need to test tunnel creation to the non-standard port separately
                if ( $CHECK_SCHEME->{ $connect->[2] }->[2] && $CHECK_SCHEME->{ $connect->[2] }->[1]->[1] != $connect->[1] ) {
                    $self->_test_connection(
                        $connect,
                        $proxy_type,
                        sub ($h) {
                            if ($h) {    # tunnel creation ok
                                $cb->($proxy_type);
                            }
                            else {       # tunnel creation failed
                                $cb->(0);
                            }

                            return;
                        }
                    );
                }
                else {
                    # scheme and tunnel was tested in single connection
                    $cb->($proxy_type);
                }
            }

            return;
        }
    );

    return;
}

sub _test_connection ( $self, $connect, $proxy_type, $cb ) {
    Pcore::AE::Handle2->new(
        connect                     => $connect,
        connect_timeout             => $PROXY_TEST_TIMEOUT,
        timeout                     => $PROXY_TEST_TIMEOUT,
        persistent                  => 0,
        proxy                       => $self,
        proxy_type                  => $proxy_type,                     # connect to proxy without waiting for the slot
        _proxy_keep_thread_on_error => 1,                               # do not finish proxy thread automatically on handle destroy
        on_error                    => sub ( $h, $fatal, $message ) {
            $cb->(undef);

            return;
        },
        on_connect => sub ( $h, @ ) {
            $cb->($h);

            return;
        }
    );

    return;
}

sub _test_scheme ( $self, $scheme, $proxy_type, $cb ) {
    if ( !$CHECK_SCHEME->{$scheme}->[2] ) {    # scheme can't be tested
        $cb->(1);
    }
    elsif ( defined $self->{test_scheme}->{$scheme}->{$proxy_type} ) {    # scheme was already tested
        $cb->( $self->{test_scheme}->{$scheme}->{$proxy_type} );          # return cached result
    }
    else {                                                                # scheme wasn't tested and can be tested
        $self->_test_connection(
            $CHECK_SCHEME->{$scheme}->[1],
            $proxy_type,
            sub ($h) {
                if ($h) {                                                 # proxy connected + tunnel created
                    $CHECK_SCHEME->{$scheme}->[2]->(                      # run scheme test
                        $self, $scheme, $h,
                        $proxy_type,
                        sub ($scheme_ok) {

                            # cache scheme test result
                            $self->{test_scheme}->{$scheme}->{$proxy_type} = $scheme_ok;

                            $cb->($scheme_ok);

                            return;
                        }
                    );
                }
                else {
                    # proxy proxy connect error or tunnel create error
                    # we do not cache scheme test result in this case
                    $cb->(0);
                }

                return;
            }
        );
    }

    return;
}

sub _test_scheme_httpx ( $self, $scheme, $h, $proxy_type, $cb ) {
    if ( $proxy_type == $PROXY_TYPE_HTTP ) {
        my $auth_header = $self->userinfo ? q[Proxy-Authorization: Basic ] . $self->userinfo_b64 . $CRLF : q[];

        if ( $scheme eq 'http' ) {
            $h->push_write(qq[GET http://www.google.com/favicon.ico HTTP/1.0${CRLF}Host:www.google.com${CRLF}${auth_header}${CRLF}]);
        }
        else {
            $h->push_write(qq[GET https://www.google.com/favicon.ico HTTP/1.0${CRLF}Host:www.google.com${CRLF}${auth_header}${CRLF}]);
        }
    }
    else {
        $h->starttls('connect') if $scheme eq 'https';

        $h->push_write(qq[GET /favicon.ico HTTP/1.1${CRLF}Host: www.google.com${CRLF}${CRLF}]);
    }

    $h->read_http_res_headers(
        headers => 0,
        sub ( $hdl, $res, $error_reason ) {
            if ( $error_reason || $res->{status} != 200 ) {    # headers parsing error
                $self->_set_connect_error if $res->{status} == 407;    # HTTP proxy auth. error

                $cb->(0);
            }
            else {
                $h->push_read(
                    chunk => 10,
                    sub ( $hdl, $chunk ) {

                        # remove chunk size in case of chunked transfer encoding
                        $chunk =~ s/\A[[:xdigit:]]+\r\n//sm;

                        # cut to 4 chars
                        substr $chunk, 4, 10, q[];

                        # validate .ico header
                        if ( $chunk eq qq[\x00\x00\x01\x00] ) {
                            $cb->(1);
                        }
                        else {
                            $cb->(0);
                        }

                        return;
                    }
                );
            }

            return;
        }
    );

    return;
}

sub _test_scheme_whois ( $self, $scheme, $h, $proxy_type, $cb ) {
    $h->push_write( 'com' . $CRLF );

    $h->read_eof(
        sub ( $h, $buf_ref, $total_bytes_readed, $error_message ) {
            if ($error_message) {
                $cb->(0);
            }
            elsif ( defined $buf_ref ) {
                if ( $buf_ref->$* =~ /IANA\s+WHOIS\s+server/smi ) {

                    # signature was found, return positive result and stop reading
                    $cb->(1);

                    return;
                }
                else {
                    return 1;    # continue reading
                }
            }
            else {
                # all response readed but signature wasn't found
                $cb->(0);
            }

            return;
        }
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 329                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 511, 567             | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 548                  | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool::Proxy - Proxy lists management subsystem

=head1 SYNOPSIS

    use Pcore::Proxy::Pool;

    my $pool = Pcore::Proxy::Pool->new(
        {   source => [
                {   class => 'Tor',
                    host  => '192.168.175.1',
                    port  => 9050,
                },
                {   class   => 'List',
                    proxies => [         #
                        'connect://107.153.45.156:80',
                        'connect://23.247.255.3:80',
                        'connect://23.247.255.2:80',
                        'connect://104.144.28.45:80',
                        'connect://107.173.180.52:80',
                        'connect://155.94.218.158:80',
                        'connect://155.94.218.160:80',
                        'connect://198.23.216.57:80',
                        'connect://172.245.109.210:80',
                        'connect://107.173.180.156:80',
                    ],
                },
            ],
        }
    );

    $pool->get_proxy(
        ['connect', 'socks'],
        sub ($proxy = undef) {
            ...;

            return;
        }
    );

=head1 DESCRIPTION

=cut
