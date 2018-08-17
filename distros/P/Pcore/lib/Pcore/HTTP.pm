package Pcore::HTTP;

use Pcore -const, -export;
use Pcore::Util::Scalar qw[is_ref is_glob is_plain_coderef is_blessed_ref is_coderef is_plain_hashref];
use Pcore::Handle qw[:ALL];
use Pcore::HTTP::Response;
use Pcore::HTTP::Cookies;

our $EXPORT = {
    METHODS => [],
    TLS_CTX => [qw[$TLS_CTX_HIGH $TLS_CTX_LOW]],
    UA      => [qw[$UA_PCORE $UA_CHROME_WINDOWS $UA_CHROME_ANDROID]],
};

const our $UA_PCORE          => qq[Pcore-HTTP/$Pcore::VERSION];
const our $UA_CHROME_WINDOWS => q[Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.183 Safari/537.36 Vivaldi/1.96.1147.55];
const our $UA_CHROME_ANDROID => q[Mozilla/5.0 (Linux; Android 7.1.1; G8231 Build/41.2.A.0.219; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/59.0.3071.125 Mobile Safari/537.36];

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

# $status => $switch_method_to_GET
const our $REDIRECT => {
    301 => 0,    # if method is not HEAD/GET - ask user and repeat request with original method
    302 => 1,    # if method is not HEAD/GET - ask user and repeat request with original method
    303 => 1,    # always change method to GET, used in POST-GET requeusts chain
    307 => 0,    # do not change method
    308 => 0,    # do not change method
};

# generate subs
for my $method ( keys $HTTP_METHODS->%* ) {
    my $sub_name = $method =~ tr/A-Z-/a-z_/r;

    eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        *$sub_name = sub {
            return &request( method => q[$method], 'url', \@_ );
        };
PERL

    # create alias for export
    no strict qw[refs];
    *{"http_$sub_name"} = \&{$sub_name};
    push $EXPORT->{METHODS}->@*, "http_$sub_name";
}

const our $ENCODE_GZIP_DEFLATE => eval { require Compress::Raw::Zlib }    ? 1 : 0;
const our $ENCODE_BROTLI       => eval { require IO::Uncompress::Brotli } ? 1 : 0;
const our $ACCEPT_ENCODING => join ',', $ENCODE_GZIP_DEFLATE ? ( 'gzip', 'deflate' ) : (), $ENCODE_BROTLI ? 'br' : ();

# mirror($target_path, $url, $params) or mirror($target_path, $url, $args)
# additional params supported:
# no_cache => 1;
# TODO implement
sub mirror ( $target, $url, @args ) {
    ...;

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
    my $cb = @_ % 2 ? pop : ();

    my %args = (
        method => undef,
        url    => undef,

        max_redirects => 7,    # max. redirects

        accept_compressed => 1,    # add "Accept-Encodiing" header
        decompress        => 1,    # automatically decompress

        cookies => undef,          # 1 - create temp cookie jar object, HashRef - use as cookies storage

        persistent => 0,           # persistent timeout in seconds, proxy connection can't be persistent

        mem_buf_size => undef,     # write data to fh if data length > this value, undef - always store in memory, 0 - always store to file

        # handle_params
        connect_timeout => undef,           # handle connect timeout
        timeout         => 300,             # timeout in seconds
        tls_ctx         => $TLS_CTX_HIGH,
        bind_ip         => undef,
        read_size       => undef,
        proxy           => undef,

        headers => undef,
        data    => undef,

        # callbacks
        on_progress => undef,               # 1 - create progress indicator, HashRef - progress indicator params, CodeRef - on_progress callback
        on_headers  => undef,
        on_data     => undef,
        @_,
    );

    # parse url
    $args{url} = P->uri( $args{url}, base => 'http://', authority => 1 ) if !is_ref $args{url};

    # proxy connections can't be persistent
    # TODO use proxy "persistent" attr
    # $args{persistent} = 0 if $args{proxy};

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

    # serialize default headers
    my ( $headers, $norm_headers );

    for ( my $i = 0; $i <= $args{headers}->$#*; $i += 2 ) {
        $norm_headers->{ lc $args{headers}->[$i] } = 1;

        $headers .= $args{headers}->[$i] . ':' . $args{headers}->[ $i + 1 ] . $CRLF if defined $args{headers}->[ $i + 1 ];
    }

    # add "User-Agent" header
    $headers .= 'User-Agent:' . $UA_PCORE . $CRLF if !$norm_headers->{'user-agent'};

    # add "Referer" header
    $headers .= 'Referer:' . $args{url}->to_string . $CRLF if !$norm_headers->{referer};

    # add "Accept-Encoding" header
    $headers .= 'Accept-Encoding:' . $ACCEPT_ENCODING . $CRLF if !$norm_headers->{'accept-encoding'} && $args{accept_compressed};

    $args{headers}      = $headers;
    $args{norm_headers} = $norm_headers;

    if ( defined wantarray ) {
        my $res = _request( \%args );

        return $cb ? $cb->($res) : $res;
    }
    else {
        Coro::async_pool(
            sub {
                my $res = _request(@_);

                $cb->($res) if $cb;

                return;
            },
            \%args
        );

        return;
    }
}

# TODO process persistent
sub _request ($args) {
    my $res = Pcore::HTTP::Response->new( {
        status => 0,
        url    => $args->{url},
    } );

    while () {

        # validate url
        $res->set_status( $HANDLE_STATUS_PROTOCOL_ERROR, q[Invalid url scheme] ) || last if !$res->{url}->is_http;

        # connect
        my $h = P->handle(
            $res->{url},
            persistent      => $args->{persistent},
            connect_timeout => $args->{connect_timeout},
            timeout         => $args->{timeout},
            tls_ctx         => $args->{tls_ctx},
            bind_ip         => $args->{bind_ip},
            defined $args->{read_size} ? ( read_size => $args->{read_size} ) : (),
        );

        # connect error
        $res->set_status( $h->{status}, $h->{reason} ) || last if !$h;

        # start TLS, only if TLS is required and TLS is not established yet
        if ( $res->{url}->is_secure && !$h->{tls} ) {
            $h->starttls;

            # start TLS error
            $res->set_status( $h->{status}, $h->{reason} ) || last if !$h;
        }

        # write request headers
        _write_headers( $h, $args, $res ) || last;

        # write request data
        _write_data( $h, $args, $res ) || last if defined $args->{data};

        # read response headers
        _read_headers( $h, $args, $res ) || last;

        # read response data
        _read_data( $h, $args, $res ) || last;

        # TODO process persistent

        # process redirect
        if ( $res->{is_redirect} ) {

            # last redirect
            last if $args->{max_redirects} <= 0;

            # decrement redirects counter
            $args->{max_redirects}--;

            # redirect type may require to switch request method during redirect
            if ( $REDIRECT->{ $res->{status} } ) {

                # change method to GET if original method was not "GET" or "HEAD"
                $args->{method} = 'GET' if $args->{method} ne 'HEAD';

                # do not resend request data
                delete $args->{data};
            }

            push $res->{redirects}->@*, $res;

            $res = Pcore::HTTP::Response->new( {
                status    => 0,
                url       => P->uri( $res->{headers}->{LOCATION}, base => $args->{url} ),
                redirects => delete $res->{redirects},
            } );
        }

        # last request
        else {
            last;
        }
    }

    return $res;
}

# TODO use uri method to get request path
sub _write_headers ( $h, $args, $res ) {
    my $request_path;

    # TODO use uri method to get request path
    $request_path = $res->{url}->path->to_uri . ( $res->{url}->query ? q[?] . $res->{url}->query : q[] );

    my $headers = q[];

    # add "Host" header
    $headers .= 'Host:' . $res->{url}->host->name . $CRLF if !$args->{norm_headers}->{host};

    # prepare content related headers
    if ( defined $args->{data} ) {
        if ( is_plain_coderef $args->{data} ) {
            $headers .= 'Transfer-Encoding:chunked' . $CRLF;
        }
        else {
            $headers .= 'Content-Length:' . bytes::length( is_ref $args->{data} ? $args->{data}->$* : $args->{data} ) . $CRLF;
        }
    }

    # add basic authorization
    if ( my $userinfo_b64 = $res->{url}->userinfo_b64 ) {
        $headers .= 'Authorization:Basic ' . $userinfo_b64 . $CRLF;
    }

    # close connection, if not persistent
    if ( !$args->{persistent} ) {
        $headers .= 'Connection:close' . $CRLF;
    }

    # TODO delete $args->{headers}->{PROXY_AUTHORIZATION};
    # if ( $runtime->{h}->{proxy_type} && $runtime->{h}->{proxy_type} == $PROXY_TYPE_HTTP && $runtime->{h}->{proxy}->{uri}->userinfo ) {
    #     $headers .= 'Proxy-Authorization:Basic ' . $runtime->{h}->{proxy}->{uri}->userinfo_b64 . $CRLF;
    # }

    if ( $args->{cookies} && ( my $cookies = $args->{cookies}->get_cookies( $res->{url} ) ) ) {
        $headers .= 'Cookie:' . join( ';', $cookies->@* ) . $CRLF;
    }

    # write headers
    $h->write( "$args->{method} $request_path HTTP/1.1" . $CRLF . $args->{headers} . $headers . $CRLF );

    # write error
    if ( !$h ) {
        $res->set_status( $h->{status}, $h->{reason} );

        return;
    }

    return 1;
}

sub _write_data ( $h, $args, $res ) {

    # chunked
    if ( is_plain_coderef $args->{data} ) {
        while () {
            my $chunk = $args->{data}->();

            if ( defined $chunk ) {
                if ( is_ref $chunk) {
                    $h->write( sprintf "%X$CRLF%s$CRLF", length $chunk->$*, $chunk->$* );
                }
                else {
                    $h->write( sprintf "%X$CRLF%s$CRLF", length $chunk, $chunk );
                }

                last if !$h;
            }

            # last chunk
            else {
                $h->write( '0' . $CRLF . $CRLF );

                last;
            }
        }
    }

    # buffer
    else {
        $h->write( is_ref $args->{data} ? $args->{data}->$* : $args->{data} );
    }

    # write error
    if ( !$h ) {
        $res->set_status( $h->{status}, $h->{reason} );

        return;
    }

    return 1;
}

sub _read_headers ( $h, $args, $res ) {
    my $headers = $h->read_http_res_headers;

    # read headers error
    if ( !$headers ) {
        $res->set_status( $h->{status}, $h->{reason} );

        return;
    }

    # parse SET_COOKIE header, add cookies
    $args->{cookies}->parse_cookies( $res->{url}, $headers->{headers}->{SET_COOKIE} ) if $args->{cookies} && exists $headers->{headers}->{SET_COOKIE};

    # this is a redirect
    $res->{is_redirect} = 1 if exists $headers->{headers}->{LOCATION} && exists $REDIRECT->{ $headers->{status} };

    # clean and set content length
    if ( exists $headers->{headers}->{CONTENT_LENGTH} ) {
        my $content_len = $headers->{headers}->{CONTENT_LENGTH} =~ tr/ //r;

        $res->{content_length} = $content_len if $content_len !~ /[^\d]/sm;
    }

    $res->{content_length} //= 0;

    # store response headers
    $res->{headers} = $headers->{headers};

    $res->{version} = "1.$headers->{minor_version}";

    # call "on_headers" callback, do not call during redirects
    if ( !$res->{is_redirect} && $args->{on_headers} && !$args->{on_headers}->($res) ) {
        $h->set_protocol_error(q[Request cancelled by "on_headers"]);

        $res->set_status( $h->{status}, $h->{reason} );

        return;
    }

    $res->set_status( $headers->{status}, $headers->{reason} );

    return 1;
}

# TODO read until EOF???
sub _read_data ( $h, $args, $res ) {
    my $is_chunked = $res->{headers}->{TRANSFER_ENCODING} && $res->{headers}->{TRANSFER_ENCODING} =~ /\bchunked\b/smi;

    my $decoder = do {
        if ( $args->{decompress} && $res->{headers}->{CONTENT_ENCODING} ) {

            # gzip, deflate
            if ( $ENCODE_GZIP_DEFLATE && $res->{headers}->{CONTENT_ENCODING} =~ /\b(?:gzip|deflate)\b/smi ) {
                my $x = Compress::Raw::Zlib::Inflate->new( -AppendOutput => 1, -WindowBits => Compress::Raw::Zlib::WANT_GZIP_OR_ZLIB() );

                sub ( $in_buf_ref, $out_buf_ref ) {
                    my $status = $x->inflate( $in_buf_ref, $out_buf_ref );

                    # decode error
                    if ( $status != Compress::Raw::Zlib::Z_OK() && $status != Compress::Raw::Zlib::Z_STREAM_END() ) {
                        $h->set_protocol_error('Stream decode error');

                        $res->set_status( $h->{status}, $h->{reason} );

                        return;
                    }

                    # decode ok
                    else {
                        return 1;
                    }
                };
            }

            # brotli
            elsif ( $ENCODE_BROTLI && $res->{headers}->{CONTENT_ENCODING} =~ /\bbr\b/smi ) {
                my $x = IO::Uncompress::Brotli->create;

                sub ( $in_buf_ref, $out_buf_ref ) {
                    $out_buf_ref->$* = eval { $x->decompress( $in_buf_ref->$* ) };    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

                    # decode error
                    if ($@) {
                        $h->set_protocol_error('Stream decode error');

                        $res->set_status( $h->{status}, $h->{reason} );

                        return;
                    }

                    # decode ok
                    else {
                        return 1;
                    }
                };
            }
        }
    };

    # data is not expected
    # TODO read until EOF???
    return 1 if !$is_chunked && !$res->{content_length};

    # reader is not needed
    if ( !defined $args->{mem_buf_size} && !$args->{on_progress} && !$args->{on_data} ) {
        my $data;

        if ($is_chunked) {
            $data = $h->read_http_chunked_data( headers => $res->{headers} );
        }
        else {
            $data = $h->read_chunk( $res->{content_length} );
        }

        # read error
        if ( !$data ) {
            $res->set_status( $h->{status}, $h->{reason} );

            return;
        }

        # decode data
        elsif ($decoder) {

            # decode error
            return if !$decoder->( $data, \my $decoded_data );

            # decode ok
            $res->{data} = \$decoded_data;
        }

        # data is not requires decoding
        else {
            $res->{data} = $data;
        }

        $res->{content_length} = length $res->{data}->$*;
    }

    # reader is required
    else {
        my $on_read = sub ( $buf_ref, $total_bytes ) {
            state $expected_content_length = $res->{content_length};
            state $total_decoded_bytes     = 0;
            state $is_fh                   = 0;

            # decode buffer
            if ($decoder) {

                # decode error
                return if !$decoder->( $buf_ref, \my $decoded_data );

                # decode buffer is too small, continue reading
                return 1 if !length $decoded_data;

                # decode ok
                $buf_ref = \$decoded_data;

                $total_decoded_bytes += length $buf_ref->$*;
            }

            # don't need to decode
            else {
                $total_decoded_bytes = $total_bytes;
            }

            # "on_progress" callback, is not called for redirects
            $args->{on_progress}->( $expected_content_length, $total_bytes ) if $args->{on_progress} && !$res->{is_redirect};

            # "on_data" callback, is not called for redirects
            if ( $args->{on_data} && !$res->{is_redirect} ) {
                if ( !$args->{on_data}->( $buf_ref, $total_decoded_bytes ) ) {
                    $h->set_protocol_error(q[Request cancelled by "on_data"]);

                    return;
                }
            }

            # store data in result
            else {
                if ($is_fh) {
                    syswrite $res->{data}, $buf_ref->$* or do {
                        $h->set_protocol_error($!);

                        return;
                    };
                }
                else {
                    $res->{data}->$* .= $buf_ref->$*;

                    if ( defined $args->{mem_buf_size} && length $res->{data}->$* > $args->{mem_buf_size} ) {
                        my $fh = P->file->tempfile;

                        syswrite $fh, $res->{data}->$* or do {
                            $h->set_protocol_error($!);

                            return;
                        };

                        $res->{data} = $fh;

                        $is_fh = 1;
                    }
                }
            }

            $res->{content_length} = $total_decoded_bytes;

            return 1;
        };

        # init "on_progress" indicator
        $args->{on_progress}->( $res->{content_length}, 0 ) if $args->{on_progress} && !$res->{is_redirect};

        my $bytes;

        if ($is_chunked) {
            $bytes = $h->read_http_chunked_data( on_read => $on_read, headers => $res->{headers} );
        }
        else {
            $bytes = $h->read_chunk( $res->{content_length}, on_read => $on_read );
        }

        # data read error
        if ( !defined $bytes ) {

            # unexpected EOF or other error, maybe timeout
            $res->set_status( $h->{status}, $h->{reason} );

            undef $res->{data};

            $res->{content_length} = 0;

            return;
        }

        # rewind fh
        $res->{data}->seek( 0, 0 ) if is_glob $res->{data};
    }

    return 1;
}

sub _get_on_progress_cb (%args) {
    state $init = !!require Pcore::Util::Term::Progress;

    return sub ( $content_length, $bytes_received ) {
        state $indicator;

        if ( !$bytes_received ) {    # called after headers received
            $args{network} = 1;

            $args{total} = $content_length;

            $indicator = Pcore::Util::Term::Progress::get_indicator(%args);
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
## |    3 | 75                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 96                   | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 138                  | * Subroutine "request" with high complexity score (22)                                                         |
## |      | 251                  | * Subroutine "_request" with high complexity score (21)                                                        |
## |      | 476                  | * Subroutine "_read_data" with high complexity score (47)                                                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 89                   | CodeLayout::ProhibitQuotedWordLists - List of quoted literal words                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 124                  | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 211                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
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
