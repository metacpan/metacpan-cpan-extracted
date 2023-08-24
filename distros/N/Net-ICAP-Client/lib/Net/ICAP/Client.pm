package Net::ICAP::Client;

use strict;
use warnings;
use English qw(-no_match_vars);
use IO::Socket::INET();
use IO::Socket::SSL();
use Carp();
use URI();
use HTTP::Request();
use HTTP::Response();
use POSIX();

our $VERSION = '0.08';

sub _CHUNK_SIZE                { return 4096 }
sub _FILE_READ_SIZE            { return 8192 }
sub _ENTIRE_ICAP_HEADERS_REGEX { return qr/\A(.*?)\r?\n\r?\n/smx }
sub _STAT_SIZE_IDX             { return 7 }
sub _DEBUG_PREFIX_SIZE         { return 3 }
sub _ICAP_RESPONSE_PEEK_SIZE   { return 1 }

sub new {
    my ( $class, $uri, %params ) = @_;
    my $self = {
        _uri           => URI->new($uri),
        _agent         => "perl($class) v$VERSION",
        _allow_204     => 1,
        _allow_preview => 1,
    };
    if ( $self->{_uri}->_scheme() eq 'icaps' ) {
        $self->{_ssl} = { SSL_verify_mode => 1 };
        foreach my $possible_ca_file (
            '/etc/pki/tls/certs/ca-bundle.crt',
            '/usr/share/ssl/certs/ca-bundle.crt',
          )
        {
            if ( -f $possible_ca_file ) {
                $self->{_ssl}->{SSL_ca_file} = $possible_ca_file;
            }
        }
        foreach my $possible_ca_path ( '/usr/share/ca-certificates', ) {
            if ( -f $possible_ca_path ) {
                $self->{_ssl}->{SSL_ca_path} = $possible_ca_path;
            }
        }
        $self->{_ssl}->{SSL_verifycn_scheme} = 'http';
        $self->{_ssl}->{SSL_verifycn_name}   = $self->{_uri}->host();
        delete $params{SSL};
    }
    foreach my $key ( sort { $a cmp $b } keys %params ) {
        if ( $key =~ /^SSL_/smx ) {
            $self->{_ssl}->{$key} = delete $params{$key};
        }
    }
    bless $self, $class;
    return $self;
}

sub debug {
    my ( $self, $debug ) = @_;
    my $old = $self->{_debug};
    if ( @ARG > 1 ) {
        $self->{_debug} = $debug;
    }
    return $old;
}

sub allow_204 {
    my ( $self, $allow_204 ) = @_;
    my $old = $self->{_allow_204};
    if ( @ARG > 1 ) {
        $self->{_allow_204} = $allow_204;
    }
    return $old;
}

sub allow_preview {
    my ( $self, $allow_preview ) = @_;
    my $old = $self->{_allow_preview};
    if ( @ARG > 1 ) {
        $self->{_allow_preview} = $allow_preview;
    }
    return $old;
}

sub _scheme {
    my ($self) = @_;
    return $self->uri()->scheme();
}

sub uri {
    my ($self) = @_;
    return $self->{_uri};
}

sub max_connections {
    my ($self) = @_;
    $self->_options();
    return $self->{_options}->{max_connections};
}

sub service {
    my ($self) = @_;
    $self->_options();
    return $self->{_options}->{service};
}

sub ttl {
    my ($self) = @_;
    $self->_options();
    return $self->{_options}->{ttl};
}

sub preview_size {
    my ($self) = @_;
    $self->_options();
    return $self->{_options}->{preview};
}

sub server_allows_204 {
    my ($self) = @_;
    $self->_options();
    return $self->{_options}->{allowed}->{'204'};
}

sub _debug {
    my ( $self, $string ) = @_;
    if ( $self->{_debug} ) {
        my $direction = substr $string, 0, _DEBUG_PREFIX_SIZE(), q[];
        $direction eq '>> '
          or $direction eq '<< '
          or Carp::croak('Incorrectly formatted debug line');
        if (   ( defined $self->{_previous_direction} )
            && ( $self->{_previous_direction} eq $direction ) )
        {
            $self->{_debug_buffer} .= $string;
        }
        elsif ( $self->{_previous_direction} ) {
            my $quoted_previous_direction =
              quotemeta $self->{_previous_direction};
            $self->{_debug_buffer} =~
              s/(\r?\n)/$1$self->{_previous_direction}/smxg;
            $self->{_debug_buffer} =~ s/\A/$self->{_previous_direction}/smxg;
            $self->{_debug_buffer} =~ s/$quoted_previous_direction\Z//smxg;
            print {*STDERR} "$self->{_debug_buffer}"
              or Carp::croak("Failed to write to STDERR:$EXTENDED_OS_ERROR");
            $self->{_debug_buffer} = $string;
        }
        else {
            $self->{_debug_buffer} = $string;
        }
        while ( $self->{_debug_buffer} =~ s/\A([^\n]+\r?\n)//smx ) {
            print {*STDERR} "$direction$1"
              or Carp::croak("Failed to write to STDERR:$EXTENDED_OS_ERROR");
        }
        $self->{_previous_direction} = $direction;
    }
    return;
}

sub _debug_flush {
    my ($self) = @_;
    if ( $self->{_debug} ) {
        my $quoted_previous_direction = quotemeta $self->{_previous_direction};
        $self->{_debug_buffer} =~ s/(\r?\n)/$1$self->{_previous_direction}/smxg;
        $self->{_debug_buffer} =~ s/\A/$self->{_previous_direction}/smxg;
        $self->{_debug_buffer} =~ s/$quoted_previous_direction\Z//smxg;
        print {*STDERR} "$self->{_debug_buffer}"
          or Carp::croak("Failed to write to STDERR:$EXTENDED_OS_ERROR");
        $self->{_debug_buffer} = q[];
    }
    return;
}

sub _write {
    my ( $self, $string ) = @_;
    my $icap_uri = $self->uri();
    my $socket   = $self->_socket();
    $self->_debug(">> $string");
    my $number_of_bytes = syswrite $socket, "$string"
      or Carp::croak(
        "Failed to write to icap server at $icap_uri:$EXTENDED_OS_ERROR");
    return $number_of_bytes;
}

sub _socket {
    my ($self) = @_;
    return $self->{_socket};
}

sub _connect {
    my ($self) = @_;
    if ( !$self->{_socket} ) {
        my $socket_class = 'IO::Socket::INET';
        my %options;
        if ( $self->_scheme() eq 'icaps' ) {
            $socket_class = 'IO::Socket::SSL';
            %options      = %{ $self->{_ssl} };
        }
        my $socket = $socket_class->new(
            PeerAddr => $self->uri()->host(),
            PeerPort => $self->uri()->port(),
            Proto    => 'tcp',
            %options,
          )
          or Carp::croak(
                'Failed to connect to '
              . $self->uri()->host()
              . ' on port '
              . $self->uri()->port() . q[:]
              . (
                  $socket_class eq 'IO::Socket::SSL'
                ? $socket_class->errstr()
                : $EXTENDED_OS_ERROR
              )
          );

        $self->{_socket} = $socket;
    }
    return $self->{_socket};
}

sub _disconnect {
    my ($self) = @_;
    delete $self->{_socket};
    return;
}

sub _process_icap_headers {
    my ( $self, $icap_headers, $icap_method ) = @_;
    my $quoted_pair   = qr/\\./smx;
    my $qdtext        = qr/[^"]/smx;
    my $quoted_string = qr/"((?:$quoted_pair|$qdtext)+)"/smx;
    if ( $icap_headers =~ /\r?\nISTag:[ ]*$quoted_string(?:\r?\n|$)/smx ) {
        $self->{_is_tag} = ($1);
    }
    elsif ( $icap_headers =~ /\r?\nISTag:[ ]*(\S+)(?:\r?\n|$)/smx )
    {    # This violates RFC but is necessary to get the c-icap project to work
        $self->{_is_tag} = ($1);
    }
    if ( $icap_method eq 'OPTIONS' ) {
        delete $self->{_options};
        if ( $icap_headers =~ /\r?\nMethods:[ ]*(.*?)(?:\r?\n|$)/smx ) {
            foreach my $method ( split /,[ ]*/smx, $1 ) {
                $self->{_options}->{methods}->{$method} = 1;
            }
        }
        if ( $icap_headers =~ /\r?\nPreview:[ ]*(\d+)(?:\r?\n|$)/smx ) {
            $self->{_options}->{preview} = $1;
        }
        if ( $icap_headers =~ /\r?\nService:[ ]*(.*?)(?:\r?\n|$)/smx ) {
            $self->{_options}->{service} = $1;
        }
        if ( $icap_headers =~ /\r?\nMax\-Connections:[ ]*(\d+)(?:\r?\n|$)/smx )
        {
            $self->{_options}->{max_connections} = $1;
        }
        if ( $icap_headers =~ /\r?\nOptions\-TTL:[ ]*(\d+)(?:\r?\n|$)/smx ) {
            $self->{_options}->{ttl}    = $1;
            $self->{_options}->{expiry} = time + $1;
        }
        if ( $icap_headers =~ /\r?\nAllow:[ ]*(.*?)(?:\r?\n|$)/smx ) {
            foreach my $allowed ( split /,[ ]*/smx, $1 ) {
                $self->{_options}->{allowed}->{$allowed} = 1;
            }
        }
    }
    return;
}

sub _get_icap_header {
    my ( $self, $peek_buffer ) = @_;
    $peek_buffer = defined $peek_buffer ? $peek_buffer : q[];
    my $entire_icap_headers_regex = _ENTIRE_ICAP_HEADERS_REGEX();
    my $icap_uri                  = $self->uri();
    my $socket                    = $self->_socket();
    while ( $peek_buffer !~ /$entire_icap_headers_regex/smx ) {
        sysread $socket, my $buffer, _ICAP_RESPONSE_PEEK_SIZE()
          or Carp::croak("Failed to read from $icap_uri:$EXTENDED_OS_ERROR");
        $peek_buffer .= $buffer;
    }
    if ( $peek_buffer =~ /^ICAP\/1[.]0[ ]([45]\d\d)[ ]/smx ) {
        $self->_disconnect();
        Carp::croak("ICAP Server returned a $1 error");
    }
    return $peek_buffer;
}

sub _icap_response {
    my ( $self, %params ) = @_;
    my $icap_uri    = $self->uri();
    my $socket      = $self->_socket();
    my $peek_buffer = $self->_get_icap_header( $params{peek_buffer} );
    $self->_debug("<< $peek_buffer");
    my $entire_icap_headers_regex = _ENTIRE_ICAP_HEADERS_REGEX();
    my ( $headers, $body_handle );
    if ( $peek_buffer =~ s/$entire_icap_headers_regex//smx ) {
        my ($icap_headers) = ($1);
        $self->_process_icap_headers( $icap_headers, $params{icap_method} );
        my $encapsulated_header_regex =
qr/\r?\nEncapsulated:[ ]?(?:re[sq]\-hdr=(\d+),[ ]?)?(req|res|null)\-body=(\d+)(?:\r?\n|$)/smx;
        if ( $icap_headers =~ /$encapsulated_header_regex/smx ) {
            my ( $header_start_position, $type, $body_start_position ) =
              ( $1, $2, $3 );
            if ( defined $header_start_position ) {
                substr $peek_buffer, 0, $header_start_position, q[];
                my $header_content = substr $peek_buffer, 0,
                  $body_start_position, q[];
                sysread $socket, my $buffer,
                  $body_start_position - ( length $header_content )
                  or Carp::croak(
                    "Failed to read from $icap_uri:$EXTENDED_OS_ERROR");
                $self->_debug("<< $buffer");
                $header_content .= $buffer;
                if ( $type eq 'res' ) {
                    $headers = HTTP::Response->parse($header_content);
                }
                elsif ( $type eq 'req' ) {
                    $headers = HTTP::Request->parse($header_content);
                }
            }
            if ( $type eq 'null' ) {
            }
            else {
                $body_handle = File::Temp::tempfile();
                while ( my $buffer = $self->_read_chunk() ) {
                    $body_handle->print($buffer);
                }
                $body_handle->seek( Fcntl::SEEK_SET(), 0 )
                  or Carp::croak(
"Failed to seek to start of temporary file:$EXTENDED_OS_ERROR"
                  );
            }
        }
        elsif ( $icap_headers =~ /^ICAP\/1[.]0[ ]204[ ]/smx ) {
            $self->_process_icap_headers( $icap_headers, $params{icap_method} );
            $self->_reset_content_handle( $params{content_handle} );
            $self->_debug_flush();
            if ( defined $params{response} ) {
                return ( $params{response}, $params{content_handle} );
            }
            else {
                return ( $params{request}, $params{content_handle} );
            }
        }
        else {
            Carp::croak('Unable to parse Encapsulated header');
        }
    }
    else {
        Carp::croak('Unable to parse ICAP header');
    }
    $self->_debug_flush();
    return ( $headers, $body_handle );
}

sub _read_chunk {
    my ($self)       = @_;
    my $icap_uri     = $self->uri();
    my $socket       = $self->_socket();
    my $chunk_buffer = q[];
    my $chunk_regex  = qr/([a-f\d]+)\r?\n/smxi;
    while ( $chunk_buffer !~ /$chunk_regex/smxi ) {
        sysread $socket, my $byte, 1
          or Carp::croak("Failed to read from $icap_uri:$EXTENDED_OS_ERROR");
        $chunk_buffer .= $byte;
    }
    $self->_debug("<< $chunk_buffer");
    if ( $chunk_buffer =~ /^$chunk_regex/smxi ) {
        my ($chunk_length) = ($1);
        if ( hex $chunk_length == 0 ) {
            my $length_of_crlf = length $Socket::CRLF;
            sysread $socket, my $chunk_content, $length_of_crlf
              or
              Carp::croak("Failed to read from $icap_uri:$EXTENDED_OS_ERROR");
            $self->_debug("<< $chunk_content");
            return;
        }
        else {
            sysread $socket, my $chunk_content, hex $chunk_length
              or
              Carp::croak("Failed to read from $icap_uri:$EXTENDED_OS_ERROR");
            $self->_debug("<< $chunk_content");
            return $chunk_content;
        }
    }
    else {
        Carp::croak('Failed to parse chunking length');
    }
}

sub _write_in_chunks {
    my ( $self, $content ) = @_;
    my $CRLF = $Socket::CRLF;
    while ($content) {
        my $chunk = substr $content, 0, _CHUNK_SIZE(), q[];
        $self->_write(
            POSIX::sprintf( '%x', ( length $chunk ) ) . "$CRLF$chunk$CRLF" );
    }
    return;
}

sub is_tag {
    my ($self) = @_;
    $self->_options();
    return $self->{_is_tag};
}

sub agent {
    my ( $self, $agent ) = @_;
    my $old = $self->{_agent};
    if ( @ARG > 1 ) {
        $self->{_agent} = $agent;
    }
    return $old;
}

sub _options {
    my ($self) = @_;
    if (   ( defined $self->{_options} )
        && ( defined $self->{_options}->{expiry} )
        && ( defined $self->{_options}->{expiry} < time ) )
    {
    }
    else {
        $self->_connect();
        my $CRLF        = $Socket::CRLF;
        my $icap_uri    = $self->uri();
        my $icap_host   = $icap_uri->host();
        my $icap_agent  = $self->agent();
        my $icap_method = 'OPTIONS';
        $self->_write(
"$icap_method $icap_uri ICAP/1.0${CRLF}Host: $icap_host${CRLF}User-Agent: $icap_agent${CRLF}Encapsulated: null-body=0$CRLF$CRLF"
        );
        $self->_icap_response( icap_method => $icap_method );
    }
    return;
}

sub _determine_icap_preview_header {
    my ( $self, $message, $content_handle ) = @_;
    my $preview_header = q[];
    if ( ( $self->allow_preview() ) && ( defined $self->preview_size() ) ) {
        my $content_size;
        if ( defined $content_handle ) {
            my @stat = stat $content_handle;
            scalar @stat
              or
              Carp::croak("Failed to stat content handle:$EXTENDED_OS_ERROR");
            $content_size = $stat[ _STAT_SIZE_IDX() ];
        }
        elsif ( my $content = $message->content() ) {
            $content_size = length $content;
        }
        if (   ( defined $content_size )
            && ( $content_size > $self->preview_size() ) )
        {
            my $CRLF = $Socket::CRLF;
            $preview_header = 'Preview: ' . $self->preview_size() . $CRLF;
        }
    }
    return $preview_header;
}

sub _determine_icap_204_header {
    my ($self)     = @_;
    my $header_204 = q[];
    my $CRLF       = $Socket::CRLF;
    if ( ( $self->allow_204() ) && ( $self->server_allows_204() ) ) {
        $header_204 .= 'Allow: 204' . $CRLF;
    }
    return $header_204;
}

sub _get_request_headers {
    my ( $self, $request ) = @_;
    my $request_headers = q[];
    if ( defined $request ) {
        my $http_uri  = $request->uri();
        my $http_host = $http_uri->host();
        my $CRLF      = $Socket::CRLF;
        $request_headers =
            $request->method() . q[ ]
          . $request->uri()->path_query() . q[ ]
          . ( $request->protocol() || 'HTTP/1.1' )
          . "${CRLF}Host: $http_host$CRLF"
          . $request->headers()->as_string($CRLF)
          . $CRLF;
    }
    return $request_headers;
}

sub _get_response_headers {
    my ( $self, $request, $response ) = @_;
    my $response_headers = q[];
    if ( defined $response ) {
        my $CRLF = $Socket::CRLF;
        $response_headers =
          ( defined $request
              && $request->protocol() ? $request->protocol() : 'HTTP/1.1' )
          . q[ ]
          . $response->code() . q[ ]
          . $response->message()
          . $CRLF
          . $response->headers()->as_string($CRLF)
          . $CRLF;
    }
    return $response_headers;
}

sub response {
    my ( $self, $request, $response, $content_handle ) = @_;
    $self->_connect();
    my $request_headers  = $self->_get_request_headers($request);
    my $response_headers = $self->_get_response_headers( $request, $response );
    my $icap_uri         = $self->uri();
    my $icap_host        = $icap_uri->host();
    my $icap_agent       = $self->agent();
    my $icap_method      = 'RESPMOD';
    my $preview_header =
      $self->_determine_icap_preview_header( $response, $content_handle );

    my $header_204 = $self->_determine_icap_204_header();
    my $CRLF       = $Socket::CRLF;
    my $req_hdr    = defined $request ? 'req-hdr=0, ' : q[];
    $self->_write(
"$icap_method $icap_uri ICAP/1.0${CRLF}Host: $icap_host${CRLF}User-Agent: $icap_agent${CRLF}${preview_header}${header_204}Encapsulated: ${req_hdr}res-hdr="
          . ( length $request_headers )
          . ', res-body='
          . ( ( length $request_headers ) + ( length $response_headers ) )
          . "$CRLF$CRLF$request_headers$response_headers" );

    if ($preview_header) {
        if ( defined $content_handle ) {
            my $bytes_read;
            while ( $bytes_read = sysread $content_handle, my $content,
                $self->preview_size() )
            {
                $self->_write_in_chunks($content);
                last;
            }
            defined $bytes_read
              or Carp::croak(
                "Failed to read from content handle:$EXTENDED_OS_ERROR");
        }
        elsif ( my $content = $response->content() ) {
            my $preview = substr $content, 0, $self->preview_size();
            $response->content($content);
            $self->_write_in_chunks($preview);
        }
        $self->_write_terminating_chunk();
        my $entire_icap_headers_regex = _ENTIRE_ICAP_HEADERS_REGEX();
        my $socket                    = $self->_socket();
        my $peek_buffer               = q[];
        while ( $peek_buffer !~ /$entire_icap_headers_regex/smx ) {
            sysread $socket, my $buffer, _ICAP_RESPONSE_PEEK_SIZE()
              or
              Carp::croak("Failed to read from $icap_uri:$EXTENDED_OS_ERROR");
            $self->_debug("<< $buffer");
            $peek_buffer .= $buffer;
        }
        if ( $peek_buffer =~ /$entire_icap_headers_regex/smx ) {
            my ($icap_headers) = ($1);
            $self->_process_icap_headers( $icap_headers, $icap_method );
        }
        if ( $peek_buffer =~ /^ICAP\/1[.]0[ ]100[ ]/smx ) {
        }
        elsif ( $peek_buffer =~ /^ICAP\/1[.]0[ ]204[ ]/smx ) {
            $self->_reset_content_handle($content_handle);
            return ( $response, $content_handle );
        }
        elsif ( $peek_buffer =~ /^ICAP\/1[.]0[ ]([45]\d\d)[ ]/smx ) {
            $self->_disconnect();
            Carp::croak("ICAP Server returned a $1 error");
        }
        else {
            return $self->_icap_response(
                icap_method    => $icap_method,
                peek_buffer    => $peek_buffer,
                request        => $request,
                response       => $response,
                content_handle => $content_handle
            );
        }
    }
    if ( defined $content_handle ) {
        my $bytes_read;
        while ( $bytes_read = read $content_handle, my $content,
            _FILE_READ_SIZE() )
        {
            $self->_write_in_chunks($content);
        }
        defined $bytes_read
          or
          Carp::croak("Failed to read from content handle:$EXTENDED_OS_ERROR");
    }
    elsif ( my $content = $response->content() ) {
        if ($preview_header) {
            substr $content, 0, $self->preview_size(), q[];
        }
        $self->_write_in_chunks($content);
    }
    $self->_write_terminating_chunk();
    return $self->_icap_response(
        icap_method    => $icap_method,
        request        => $request,
        response       => $response,
        content_handle => $content_handle
    );
}

sub _reset_content_handle {
    my ( $self, $content_handle ) = @_;
    if ( defined $content_handle ) {
        seek $content_handle, Fcntl::SEEK_SET(), 0
          or Carp::croak(
            "Failed to seek to start of content handle:$EXTENDED_OS_ERROR");
    }
    return;
}

sub request {
    my ( $self, $request, $content_handle ) = @_;
    $self->_connect();
    my $request_headers = $self->_get_request_headers($request);
    my $icap_uri        = $self->uri();
    my $icap_host       = $icap_uri->host();
    my $icap_agent      = $self->agent();
    my $icap_method     = 'REQMOD';
    my $preview_header =
      $self->_determine_icap_preview_header( $request, $content_handle );

    my $header_204 = $self->_determine_icap_204_header();
    my $CRLF       = $Socket::CRLF;
    $self->_write(
"$icap_method $icap_uri ICAP/1.0${CRLF}Host: $icap_host${CRLF}User-Agent: $icap_agent${CRLF}${preview_header}${header_204}Encapsulated: req-hdr=0, req-body="
          . ( length $request_headers )
          . "$CRLF$CRLF$request_headers" );
    if ($preview_header) {
        if ( defined $content_handle ) {
            my $bytes_read;
            while ( $bytes_read = sysread $content_handle, my $content,
                $self->preview_size() )
            {
                $self->_write_in_chunks($content);
                last;
            }
            defined $bytes_read
              or Carp::croak(
                "Failed to read from content handle:$EXTENDED_OS_ERROR");
        }
        elsif ( my $content = $request->content() ) {
            my $preview = substr $content, 0, $self->preview_size();
            $request->content($content);
            $self->_write_in_chunks($preview);
        }
        $self->_write_terminating_chunk();
        my $entire_icap_headers_regex = _ENTIRE_ICAP_HEADERS_REGEX();
        my $socket                    = $self->_socket();
        my $peek_buffer               = q[];
        while ( $peek_buffer !~ /$entire_icap_headers_regex/smx ) {
            sysread $socket, my $buffer, _ICAP_RESPONSE_PEEK_SIZE()
              or
              Carp::croak("Failed to read from $icap_uri:$EXTENDED_OS_ERROR");
            $self->_debug("<< $buffer");
            $peek_buffer .= $buffer;
        }
        if ( $peek_buffer =~ /$entire_icap_headers_regex/smx ) {
            my ($icap_headers) = ($1);
            $self->_process_icap_headers( $icap_headers, $icap_method );
        }
        if ( $peek_buffer =~ /^ICAP\/1[.]0[ ]100[ ]/smx ) {
        }
        elsif ( $peek_buffer =~ /^ICAP\/1[.]0[ ]204[ ]/smx ) {
            $self->_reset_content_handle($content_handle);
            return ( $request, $content_handle );
        }
        elsif ( $peek_buffer =~ /^ICAP\/1[.]0[ ]([45]\d\d)[ ]/smx ) {
            $self->_disconnect();
            Carp::croak("ICAP Server returned a $1 error");
        }
        else {
            return $self->_icap_response(
                icap_method    => $icap_method,
                peek_buffer    => $peek_buffer,
                request        => $request,
                content_handle => $content_handle
            );
        }
    }
    if ( defined $content_handle ) {
        my $bytes_read;
        while ( $bytes_read = read $content_handle, my $content,
            _FILE_READ_SIZE() )
        {
            $self->_write_in_chunks($content);
        }
        defined $bytes_read
          or
          Carp::croak("Failed to read from content handle:$EXTENDED_OS_ERROR");
    }
    elsif ( my $content = $request->content() ) {
        if ($preview_header) {
            substr $content, 0, $self->preview_size(), q[];
        }
        $self->_write_in_chunks($content);
    }
    $self->_write_terminating_chunk();
    return $self->_icap_response(
        icap_method    => $icap_method,
        request        => $request,
        content_handle => $content_handle
    );
}

sub _write_terminating_chunk {
    my ($self) = @_;
    my $CRLF = $Socket::CRLF;
    return $self->_write("0$CRLF$CRLF");
}

1;
__END__

=head1 NAME

Net::ICAP::Client - A client implementation of the ICAP (RFC 3507) protocol

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

    use Net::ICAP::Client;

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $request = HTTP::Request->new( 'POST' => 'https://www.example.com/path' );
    my ( $headers, $body ) = $icap->request( $request );
    if ($headers->isa('HTTP::Request') {
	# forward request to intended destination
    } elsif ($headers->isa('HTTP::Response') {
        # return response to original requestor
    }

=head1 DESCRIPTION

This module provides a client interface to an L<ICAP (RFC 3507) Server|http://tools.ietf.org/html/rfc3507>.  ICAP Servers are designed to inspect and modify HTTP Request and Responses before the Request is passed to backend systems or the Response goes back to the user.

=head1 SUBROUTINES/METHODS

=head2 new

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $icap = Net::ICAP::Client->new('icaps://icap-proxy.example.com/', SSL_ca_path => '/path/to/ca-bundle.crt', %other_IO_SSL_Socket_options);

By default, the SSL_verifycn_scheme, SSL_verifycn_name and SSL_verify_mode parameters are automatically set for icaps URIs, but these parameters may be overridden.

=head2 debug

$icap->debug() accepts an optional debug value and returns the current debug value

=head2 allow_204

$icap->allow_204() accepts an optional value to set whether the client will send an L<Allow: 204|https://tools.ietf.org/html/rfc3507#section-4.6> and returns the current setting

=head2 allow_preview

$icap->allow_preview() accepts an optional value to set whether the client will send an L<Preview|https://tools.ietf.org/html/rfc3507#section-4.5> and returns the current setting

=head2 agent

$icap->agent() accepts an optional User Agent string and returns the current User Agent string

=head2 server_allows_204

$icap->server_allows_204() returns true if the remote ICAP server can return a 204 (No modification needed) response.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last L<ttl|/#ttl> seconds.

=head2 is_tag

$icap->is_tag() returns the value of the remote ICAP server's L<ISTag|https://tools.ietf.org/html/rfc3507#section-4.7> header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last L<ttl|/#ttl> seconds.

=head2 service

$icap->service() returns the value of the remote ICAP server's L<Service|https://tools.ietf.org/html/rfc3507#section-4.10.2> header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last L<ttl|/#ttl> seconds.

=head2 ttl

$icap->ttl() returns the value of the remote ICAP server's L<Options-TTL|https://tools.ietf.org/html/rfc3507#section-4.10.2> header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last L<ttl|/#ttl> seconds.

=head2 max_connections

$icap->max_connections() returns the value of the remote ICAP server's L<Max-Connections|https://tools.ietf.org/html/rfc3507#section-4.10.2> header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last L<ttl|/#ttl> seconds.

=head2 preview_size

$icap->preview_size() returns the value of the remote ICAP server's L<Preview|https://tools.ietf.org/html/rfc3507#section-4.10.2> header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last L<ttl|/#ttl> seconds.

=head2 uri

$icap->uri() returns the current URI of the remote ICAP server as a L<URI|URI> object.

=head2 request

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $request_headers = HTTP::Headers->new();
    my $request = HTTP::Request->new( 'POST' => "https://www.example.com/path?name=value", $request_headers, "name2=value2" );
    my ( $request_or_response_headers, $filehandle_containing_possibly_updated_body ) = $icap->request( $request, $filehandle_containing_request_body );

$icap->request() expects an L<HTTP::Request|HTTP::Request> object and an optional filehandle.  It will return an L<HTTP::Request|HTTP::Request> or an L<HTTP::Response|HTTP::Response> object containing the request or response without the body and a filehandle containing the body.

=head2 response

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $response = HTTP::Response->new( '200', 'OK' );
    my ( $response_headers, $filehandle_containing_possibly_updated_body ) = $icap->response( $optional_request_or_undef, $response, $filehandle_containing_response_body );

$icap->response() expects an L<HTTP::Request|HTTP::Request> object (if available), an L<HTTP::Response|HTTP::Response> object and an optional filehandle.  It will return an L<HTTP::Response|HTTP::Response> object containing the response without the response body and a filehandle containing the response body.

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 DIAGNOSTICS

=over

=item C<< Failed to write to icap server at %s >>
 
Failed to write to the remote icap server.  Check network status.

=item C<< Failed to write to STDERR >>
 
Failed to write to STDERR.  Check local machine settings.
 
=item C<< Incorrectly formatted debug line >>
 
A debug call was made without being prefixed with a '>> ' or '<< '.  This is a bug in Net::ICAP::Client
 
=item C<< Failed to connect to %s on port %s >>
 
The connection to the remote icap server failed.  Check network/SSL/TLS settings and status
 
=item C<< Failed to read from %s >>
 
Failed to read from the remote icap server.  Check network status
 
=item C<< Failed to seek to start of temporary file >>
 
Failed to do a disk operation.  Check disk settings for the mount point belonging to where temp files are being created
 
=item C<< Failed to seek to start of content handle >>
 
Failed to do a disk operation.  Check disk settings for the mount point belonging to the file that are passed into the request/response method
 
=item C<< ICAP Server returned a %s error >>
 
The remote ICAP server returned an error.  The TCP connection to the remote ICAP server will be automatically disconnected.  Capture the network traffic and enter a bug report
 
=item C<< Failed to parse chunking length >>
 
This is a bug in Net::ICAP::Client
 
=item C<< Unable to parse Encapsulated header >>

The remote ICAP server did not return an Encapsulated header that could be understood by Net::ICAP::Client.  Capture the network traffic and enter a bug report
 
=item C<< Unable to parse ICAP header >>

The remote ICAP server did not return an ICAP header that could be understood by Net::ICAP::Client.  Capture the network traffic and enter a bug report
 
=item C<< Failed to read from content handle >>
 
Failed to do a disk operation.  Check disk settings for the mount point belonging to the file that are passed into the request/response method

=back
 
=head1 CONFIGURATION AND ENVIRONMENT

Net::ICAP::Client requires no configuration files or environment variables.

=head1 DEPENDENCIES

Net::ICAP::Client requires the following non-core modules
 
  HTTP::Request
  HTTP::Response
  IO::Socket::INET
  IO::Socket::SSL
  URI

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

To report a bug, or view the current list of bugs, please visit L<https://github.com/david-dick/net-icap-client/issues>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See L<http://dev.perl.org/licenses/> for more information.
