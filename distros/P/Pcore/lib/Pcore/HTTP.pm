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

    useragent     => "Pcore-HTTP/$Pcore::VERSION",    # shortcut for User-Agent header
    max_redirects => 7,                               # max. redirects

    accept_compressed => 1,                           # add ACCEPT_ENCODIING header
    decompress        => 1,                           # automatically decompress

    cookies => undef,                                 # 1 - create temp cookie jar object, HashRef - use as cookies storage

    persistent => 0,                                  # persistent timeout in seconds, proxy connection can't be persistent

    buf_size => 0,                                    # write body to fh if body length > this value, 0 - always store in memory, 1 - always store to file

    handle_params   => undef,                         # HashRef with params, that will be passed directly to AE::Handle
    connect_timeout => undef,                         # handle connect timeout
    timeout         => 300,                           # timeout in seconds
    tls_ctx         => $TLS_CTX_HIGH,
    bind_ip         => undef,
    proxy           => undef,

    headers => undef,
    body    => undef,

    on_progress   => undef,                           # 1 - create progress indicator, HashRef - progress indicator params, CodeRef - on_progress callback
    on_header     => undef,
    on_body       => undef,
    before_finish => undef,
    on_finish     => undef,
};

our $DEFAULT_HANDLE_PARAMS = {                        #
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
            if ( \@_ % 2 ) {
                return request( \@_[ 1 .. \$#_ ], method => '$method', url => \$_[0] );
            }
            else {
                return request( \@_[ 1 .. \$#_ - 1 ], method => '$method', url => \$_[0], on_finish => \$_[-1] );
            }
        };
PERL

    no strict qw[refs];

    # create alias for export
    *{"http_$sub_name"} = \&{$sub_name};

    # name sub
    P->class->set_subname( 'Pcore::HTTP::' . $sub_name, \&{$sub_name} );
}

# mirror($target_path, $url, $params) or mirror($target_path, $url, $args)
# additional params supported:
# no_cache => 1;
sub mirror ( $target, $url, @args ) {
    my ( $on_finish, %args );

    if ( @args % 2 ) {
        $on_finish = pop @args;

        %args = @args;
    }
    else {
        %args = @args;

        $on_finish = delete $args{on_finish};
    }

    $args{url} = $url;

    $args{method} ||= 'GET';

    $args{buf_size} = 1;

    $args{headers}->{IF_MODIFIED_SINCE} = P->date->from_epoch( [ stat $target ]->[9] )->to_http_date if !$args{no_cache} && -f $target;

    $args{on_finish} = sub ($res) {
        if ( $res->{status} == 200 ) {
            P->file->move( $res->{body}->path, $target );

            if ( my $last_modified = $res->headers->{LAST_MODIFIED} ) {
                my $mtime = P->date->parse($last_modified)->at_utc->epoch;

                utime $mtime, $mtime, $target or die;
            }
        }

        $on_finish->($res) if $on_finish;

        return;
    };

    return request(%args);
}

sub request {
    my %args;

    if ( @_ % 2 ) {
        %args = ( $DEFAULT->%*, @_[ 0 .. $#_ - 1 ], on_finish => $_[-1] );
    }
    else {
        %args = ( $DEFAULT->%*, @_ );
    }

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

    # on_finish wrapper
    my $before_finish = delete $args{before_finish};

    my $on_finish = delete $args{on_finish};

    my $rouse_cb = defined wantarray ? Coro::rouse_cb : ();

    $args{on_finish} = sub ($res) {

        # rewind body fh
        $res->{body}->seek( 0, 0 ) if $res->{body} && is_glob $res->{body};

        # before_finish callback
        $before_finish->($res) if $before_finish;

        # on_finish callback
        $rouse_cb ? $on_finish ? $rouse_cb->( $on_finish->($res) ) : $rouse_cb->($res) : $on_finish ? $on_finish->($res) : ();

        return;
    };

    # throw request
    Pcore::HTTP::Util::http_request( \%args );

    return $rouse_cb ? Coro::rouse_wait $rouse_cb : ();
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
## |    3 | 170                  | Subroutines::ProhibitExcessComplexity - Subroutine "request" with high complexity score (34)                   |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 156                  | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
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
