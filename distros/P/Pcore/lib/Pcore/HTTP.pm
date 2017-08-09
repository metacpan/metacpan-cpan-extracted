package Pcore::HTTP;

use Pcore -const,
  -export => {
    METHODS => [qw[http_acl http_baseline_control http_bind http_checkin http_checkout http_connect http_copy http_delete http_get http_head http_label http_link http_lock http_merge http_mkactivity http_mkcalendar http_mkcol http_mkredirectref http_mkworkspace http_move http_options http_orderpatch http_patch http_post http_pri http_propfind http_proppatch http_put http_rebind http_report http_search http_trace http_unbind http_uncheckout http_unlink http_unlock http_update http_updateredirectref http_version_control]],
    TLS_CTX => [qw[$TLS_CTX_HIGH $TLS_CTX_LOW]],
  };
use Pcore::Util::Scalar qw[is_ref is_blessed_ref is_glob is_coderef is_plain_hashref];
use Pcore::AE::Handle qw[:TLS_CTX];
use Pcore::HTTP::Util;
use Pcore::HTTP::Headers;
use Pcore::HTTP::Response;
use Pcore::HTTP::Cookies;

# 594 - errors during proxy handshake.
# 595 - errors during connection establishment.
# 596 - errors during TLS negotiation, request sending and header processing.
# 597 - errors during body receiving or processing.
# 598 - user aborted request via on_header or on_body.
# 599 - other, usually nonretryable, errors (garbled URL etc.).

our $DEFAULT = {
    method => undef,
    url    => undef,

    useragent => "Pcore-HTTP/$Pcore::VERSION",    # shortcut for User-Agent header
    recurse   => 7,                               # max. redirects

    accept_compressed => 1,                       # add ACCEPT_ENCODIING header
    decompress        => 1,                       # automatically decompress

    cookies => undef,                             # 1 - create temp cookie jar object, HashRef - use as cookies storage

    persistent => 0,                              # persistent timeout in seconds, proxy connection can't be persistent

    buf_size => 0,                                # write body to fh if body length > this value, 0 - always store in memory, 1 - always store to file

    handle_params   => undef,                     # HashRef with params, that will be passed directly to AE::Handle
    connect_timeout => undef,                     # handle connect timeout
    timeout         => 300,                       # timeout in seconds
    tls_ctx         => $TLS_CTX_HIGH,
    bind_ip         => undef,
    proxy           => undef,

    headers => undef,
    body    => undef,

    on_progress   => undef,                       # 1 - create progress indicator, HashRef - progress indicator params, CodeRef - on_progress callback
    on_header     => undef,
    on_body       => undef,
    before_finish => undef,
    on_finish     => undef,
};

our $DEFAULT_HANDLE_PARAMS = {                    #
    max_read_size => 1_048_576,
};

# $method => [$idempotent, $safe]
const our $HTTP_METHODS => {
    ACL                => [ 1, 0 ],
    'BASELINE-CONTROL' => [ 1, 0 ],
    BIND               => [ 1, 0 ],
    CHECKIN            => [ 1, 0 ],
    CHECKOUT           => [ 1, 0 ],
    CONNECT            => [ 0, 0 ],
    COPY               => [ 1, 0 ],
    DELETE             => [ 1, 0 ],
    GET                => [ 1, 1 ],
    HEAD               => [ 1, 1 ],
    LABEL              => [ 1, 0 ],
    LINK               => [ 1, 0 ],
    LOCK               => [ 0, 0 ],
    MERGE              => [ 1, 0 ],
    MKACTIVITY         => [ 1, 0 ],
    MKCALENDAR         => [ 1, 0 ],
    MKCOL              => [ 1, 0 ],
    MKREDIRECTREF      => [ 1, 0 ],
    MKWORKSPACE        => [ 1, 0 ],
    MOVE               => [ 1, 0 ],
    OPTIONS            => [ 1, 1 ],
    ORDERPATCH         => [ 1, 0 ],
    PATCH              => [ 0, 0 ],
    POST               => [ 0, 0 ],
    PRI                => [ 1, 1 ],
    PROPFIND           => [ 1, 1 ],
    PROPPATCH          => [ 1, 0 ],
    PUT                => [ 1, 0 ],
    REBIND             => [ 1, 0 ],
    REPORT             => [ 1, 1 ],
    SEARCH             => [ 1, 1 ],
    TRACE              => [ 1, 1 ],
    UNBIND             => [ 1, 0 ],
    UNCHECKOUT         => [ 1, 0 ],
    UNLINK             => [ 1, 0 ],
    UNLOCK             => [ 1, 0 ],
    UPDATE             => [ 1, 0 ],
    UPDATEREDIRECTREF  => [ 1, 0 ],
    'VERSION-CONTROL'  => [ 1, 0 ],
};

# generate subs
for my $method ( keys $HTTP_METHODS->%* ) {
    my $sub_name = lc $method =~ s/-/_/smgr;

    eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        *$sub_name = sub {
            return request( \@_[ 1 .. \$#_ ], method => '$method', url => \$_[0] );
        };
PERL

    no strict qw[refs];

    # create alias for export
    *{"http_$sub_name"} = \&{$sub_name};

    # name sub
    P->class->set_subname( 'Pcore::HTTP::' . $sub_name, \&{$sub_name} );
}

# mirror($target_path, $url, $params) or mirror($target_path, $method, $url, $params)
# additional params supported:
# no_cache => 1;
sub mirror ( $target, @ ) {
    my ( $method, $url, %args );

    if ( exists $HTTP_METHODS->{ $_[1] } ) {
        ( $method, $url, %args ) = splice @_, 1;
    }
    else {
        $method = 'GET';

        ( $url, %args ) = splice @_, 1;
    }

    $args{buf_size} = 1;

    $args{headers}->{IF_MODIFIED_SINCE} = P->date->from_epoch( [ stat $target ]->[9] )->to_http_date if !$args{no_cache} && -f $target;

    my $on_finish = delete $args{on_finish};

    $args{on_finish} = sub ($res) {
        if ( $res->status == 200 ) {
            P->file->move( $res->body->path, $target );

            if ( my $last_modified = $res->headers->{LAST_MODIFIED} ) {
                my $mtime = P->date->parse($last_modified)->at_utc->epoch;

                utime $mtime, $mtime, $target or die;
            }
        }

        $on_finish->($res) if $on_finish;

        return;
    };

    return request( %args, method => $method, url => $url );
}

sub request ( @ ) {
    my %args = ( $DEFAULT->%*, @_ );

    $args{url} = P->uri( $args{url}, base => 'http://', authority => 1 ) if !is_ref $args{url};

    # proxy connections can't be persistent
    $args{persistent} = 0 if $args{proxy};

    # create headers object
    if ( !$args{headers} ) {
        $args{headers} = Pcore::HTTP::Headers->new;
    }
    elsif ( !is_blessed_ref $args{headers} ) {
        $args{headers} = Pcore::HTTP::Headers->new( $args{headers} );
    }

    # create empty HTTP response object
    $args{res} = Pcore::HTTP::Response->new( { status => 0 } );

    # resolve cookies shortcut
    if ( $args{cookies} && !is_blessed_ref $args{cookies} ) {

        # cookies is SCALAR, create temp cookies object
        if ( !is_ref $args{cookies} ) {
            $args{cookies} = Pcore::HTTP::Cookies->new;
        }

        # cookie jar is HashRef, bless
        else {
            $args{cookies} = bless { cookies => $args{cookies} }, 'Pcore::HTTP::Cookies';
        }
    }

    # set HOST header
    $args{headers}->{HOST} = $args{url}->host->name if !exists $args{headers}->{HOST};

    # set REFERER header
    $args{headers}->{REFERER} = $args{url}->to_string if !exists $args{headers}->{REFERER};

    # set ACCEPT_ENCODING headers
    $args{headers}->{ACCEPT_ENCODING} = 'gzip' if $args{accept_compressed} && !exists $args{headers}->{ACCEPT_ENCODING};

    # add COOKIE headers
    if ( $args{cookies} && ( my $cookies = $args{cookies}->get_cookies( $args{url} ) ) ) {
        $args{headers}->add( COOKIE => join q[; ], $cookies->@* );
    }

    # merge handle_params
    if ( my $handle_params = delete $args{handle_params} ) {
        $args{handle_params} = {    #
            $DEFAULT_HANDLE_PARAMS->%*,
            $handle_params->%*,
        };
    }
    else {
        $args{handle_params} = $DEFAULT_HANDLE_PARAMS;
    }

    # use timeout as connect timeout if not defined
    $args{connect_timeout} //= $args{timeout};

    # apply useragent
    if ( my $useragent = delete $args{useragent} ) {
        $args{headers}->{USER_AGENT} = $useragent if !exists $args{headers}->{USER_AGENT};
    }

    # resolve on_progress shortcut
    if ( $args{on_progress} && !is_coderef $args{on_progress} ) {
        if ( !is_ref $args{on_progress} ) {
            $args{on_progress} = _get_on_progress_cb();
        }
        elsif ( is_plain_hashref $args{on_progress} ) {
            $args{on_progress} = _get_on_progress_cb( $args{on_progress}->%* );
        }
        else {
            die q["on_progress" can be CodeRef, HashRef or "1"];
        }
    }

    # blocking cv
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    # on_finish wrapper
    my $before_finish = delete $args{before_finish};

    my $on_finish = delete $args{on_finish};

    my $res = $args{res};

    $args{on_finish} = sub {

        # rewind body fh
        $res->body->seek( 0, 0 ) if $res->has_body && is_glob $res->body;

        # before_finish callback
        $before_finish->($res) if $before_finish;

        # on_finish callback
        $on_finish->($res) if $on_finish;

        $blocking_cv->send($res) if $blocking_cv;

        return;
    };

    # throw request
    Pcore::HTTP::Util::http_request( \%args );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub rand_ua {
    state $USER_AGENTS = [    #
        'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/600.1.25 (KHTML, like Gecko) Version/8.0 Safari/600.1.25',
        'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.1.17 (KHTML, like Gecko) Version/7.1 Safari/537.85.10',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B411 Safari/600.1.4',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65 Safari/537.36',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D257 Safari/9537.53',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B435 Safari/600.1.4',
        'Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko',
        'Mozilla/5.0 (iPad; CPU OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (Windows NT 5.1; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)',
        'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)',
        'Mozilla/5.0 (iPad; CPU OS 8_1_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B435 Safari/600.1.4',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/600.1.25 (KHTML, like Gecko) QuickLook/5.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/600.1.25 (KHTML, like Gecko) QuickLook/5.0',
        'Mozilla/5.0 (X11; Linux x86_64; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.59.10 (KHTML, like Gecko) Version/5.1.9 Safari/534.59.10',
        'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:32.0) Gecko/20100101 Firefox/32.0',
        'Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.78.2 (KHTML, like Gecko) Version/7.0.6 Safari/537.78.2',
        'Mozilla/5.0 (iPad; CPU OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D257 Safari/9537.53',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.78.2 (KHTML, like Gecko) Version/6.1.6 Safari/537.78.2',
        'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20100101 Firefox/31.0',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_0_2 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12A405 Safari/600.1.4',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B436 Safari/600.1.4',
        'Mozilla/5.0 (Windows NT 6.2; WOW64; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
        'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.104 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; Touch; rv:11.0) like Gecko',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D201 Safari/9537.53',
        'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/600.1.17 (KHTML, like Gecko) Version/6.2 Safari/537.85.10',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65 Safari/537.36',
        'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/38.0.2125.111 Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:34.0) Gecko/20100101 Firefox/34.0',
        'Mozilla/5.0 (Windows NT 6.0; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/37.0.2062.120 Chrome/37.0.2062.120 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:33.0) Gecko/20100101 Firefox/33.0',
        'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (iPad; CPU OS 8_0_2 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12A405 Safari/600.1.4',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:34.0) Gecko/20100101 Firefox/34.0',
        'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36',
        'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12A365 Safari/600.1.4',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.78.2 (KHTML, like Gecko) Version/7.0.6 Safari/537.78.2',
        'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.122 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.77.4 (KHTML, like Gecko) Version/7.0.5 Safari/537.77.4',
        'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; rv:31.0) Gecko/20100101 Firefox/31.0',
        'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.104 Safari/537.36',
    ];

    return $USER_AGENTS->[ rand @{$USER_AGENTS} ];
}

sub _get_on_progress_cb (%args) {
    return sub ( $res, $content_length, $bytes_received ) {
        state $indicator;

        if ( !$bytes_received ) {    # called after headers received
            $args{network} = 1;

            $args{total} = $content_length;

            $indicator = P->progress->get_indicator(%args);
        }
        else {
            $indicator->update( value => $bytes_received );
        }

        return;
    };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 106                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 161                  | Subroutines::ProhibitExcessComplexity - Subroutine "request" with high complexity score (31)                   |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 147                  | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
