package Net::Libwebsockets::WebSocket::Client;

use strict;
use warnings;

use Carp       ();
use URI::Split ();

use Net::Libwebsockets ();
use Net::Libwebsockets::X ();
use Promise::XS ();

#----------------------------------------------------------------------

=head1 FUNCTIONS

=head2 promise(\@code_and_reason) = connect( %OPTS )

Starts a WebSocket connection. Returns a promise that indicates that
connection’s final status.

Required %OPTS are:

=over

=item * C<url> - The target URL (e.g., C<ws://echo.websocket.org>)

=item * C<event> - The event loop interface to use.
Recognized values are:

=over

=item * C<AnyEvent> - to use L<AnyEvent>

=item * A two-member arrayref of C<[ 'IOAsync', $loop ]> where C<$loop>
is an L<IO::Async::Loop> instance.

=back

=item * C<on_ready> - Callback that “runs” the WebSocket connection
once started. Receives a L<Net::Libwebsockets::WebSocket::Courier>
instance. If this throws, that exception will cause C<connect()>’s
returned promise to reject with that value.

=back

Optional %OPTS are:

=over

=item * C<tls> - bitmask of TLS connection options, e.g.,
Net::Libwebsockets::LCCSCF_ALLOW_SELFSIGNED. Should be a mask of zero or
more of:

=over

=item * Net::Libwebsockets::LCCSCF_ALLOW_SELFSIGNED

=item * Net::Libwebsockets::LCCSCF_SKIP_SERVER_CERT_HOSTNAME_CHECK

=item * Net::Libwebsockets::LCCSCF_ALLOW_EXPIRED

=item * Net::Libwebsockets::LCCSCF_ALLOW_INSECURE

=back

=item * C<subprotocols> - arrayref of subprotocols to send

=item * C<compression> - One of:

=over

=item * A simple string that names the compression type to use.
Currently C<deflate> is the only accepted value; this indicates
permessage-deflate in its default configuration.

=item * An arrayref of compression setups to try. Each setup is
a compression name (again, only C<deflate> is accepted) and an optional
hashref of attributes.

For permessage-deflate those attributes can be any or all of:

=over

=item * C<local_context_mode> - one of:

=over

=item * C<takeover> - retain deflate’s dictionary between messages

=item * C<no_takeover> - new dictionary for each message

=back

=item * C<peer_context_mode> - ^^ ditto

=item * C<local_max_window_bits>

=item * C<peer_max_window_bits>

=back

See permessage-deflate’s specification for more about these options.

If this option is not given, we’ll use the “best default” available;
currently that means permessage-deflate in its default configuration if
it’s available, or none if Libwebsockets lacks WebSocket compression
support.

=back

=item * C<headers> - An arrayref of key-value pairs, e.g.,
C<[ 'X-Foo' =E<gt> 'foo', 'X-Bar' =E<gt> 'bar' ]>.

=item * C<ping_interval> - The amount of time (in seconds) between pings
that we’ll send. Defaults to 30 seconds.

=item * C<ping_timeout> - The amount of time (in seconds) before
we drop the connection. Defaults to 4m59s.

=back

=head3 Return Value

Returns a promise that completes once the WebSocket connection is done.
If the connection shuts down successfully then the promise resolves
with an array reference of C<[ $code, $reason ]>; otherwise the promise
rejects with one of:

=over

=item * L<Net::Libwebsockets::X::WebSocketClose>

=item * L<Net::Libwebsockets::X::ConnectionFailed>

=item * L<Net::Libwebsockets::X::General>

=back

=cut

my @_REQUIRED = qw( url event on_ready );
my %_KNOWN = map { $_ => 1 } (
    @_REQUIRED,
    'subprotocols',
    'compression',
    'headers',
    'tls',
    'ping_interval', 'ping_timeout',
    'logger',
);

my %DEFAULT = (
    ping_interval => 30,
    ping_timeout => 299,
);

sub _validate_subprotocol {
    my $str = shift;

    if (!length $str) {
        Carp::croak "Subprotocol must be nonempty";
    }

    my $valid_yn = ($str !~ tr<\x21-\x7e><>c);
    $valid_yn = ($str !~ tr|()<>@,;:\\"/[]?={}||);

    if (!$valid_yn) {
        Carp::croak "“$str” is not a valid WebSocket subprotocol name";
    }

    return;
}

sub connect {
    my (%opts) = @_;

    my @missing = grep { !$opts{$_} } @_REQUIRED;
    Carp::croak "Need: @missing" if @missing;

    my @extra = sort grep { !$_KNOWN{$_} } keys %opts;
    Carp::croak "Unknown: @extra" if @extra;

    # Tolerate ancient perls that lack “//=”:
    !defined($opts{$_}) && ($opts{$_} = $DEFAULT{$_}) for keys %DEFAULT;

    my ($url, $event, $tls_opt, $headers, $subprotocols, $logger) = @opts{'url', 'event', 'tls', 'headers', 'subprotocols', 'logger'};

    if (defined $logger) {
        if (!UNIVERSAL::isa($logger, 'Net::Libwebsockets::Logger')) {
            Carp::croak "Unknown logger: $logger";
        }
    }

    if ($subprotocols) {
        _validate_subprotocol($_) for @$subprotocols;
    }

    _validate_uint($_ => $opts{$_}) for sort keys %DEFAULT;

    my @headers_copy;

    if ($headers) {
        if ('ARRAY' ne ref $headers) {
            Carp::croak "“headers” must be an arrayref, not “$headers”!";
        }

        if (@$headers % 2) {
            Carp::croak "“headers” (@$headers) must have an even number of members!";
        }

        @headers_copy = $headers ? @$headers : ();

        for my $i ( 0 .. $#headers_copy ) {
            utf8::downgrade($headers_copy[$i]);

            # Weirdly, LWS adds the space between the key & value
            # but not the trailing colon. So let’s add it.
            #
            $headers_copy[$i] .= ':' if !($i % 2);
        }
    }

    my ($scheme, $auth, $path, $query) = URI::Split::uri_split($url);

    if ($scheme ne 'ws' && $scheme ne 'wss') {
        Carp::croak "Bad URL scheme ($scheme); use ws or wss";
    }

    $path .= "?$query" if defined $query && length $query;

    $auth =~ m<\A (.+?) (?: : ([0-9]+))? \z>x or do {
        Carp::croak "Bad URL authority ($auth)";
    };

    my ($hostname, $port) = ($1, $2);

    my $tls_flags = ($scheme eq 'ws') ? 0 : Net::Libwebsockets::_LCCSCF_USE_SSL;

    $port ||= $tls_flags ? 443 : 80;

    $tls_flags |= $tls_opt if $tls_opt;

    my $done_d = Promise::XS::deferred();

    my $loop_obj = _get_loop_obj($event);

    _new(
        $hostname, $port, $path,
        _compression_to_ext($opts{'compression'}),
        $subprotocols ? join(', ', $subprotocols) : undef,
        \@headers_copy,
        $tls_flags,
        @opts{'ping_interval', 'ping_timeout'},
        $loop_obj,
        $done_d,
        $opts{'on_ready'},
        $logger,
    );

    return $done_d->promise();
}

sub _validate_deflate_max_window_bits {
    my ($argname, $val) = @_;

    if ($val < 8 || $val > 15) {
        Carp::croak "Bad $argname (must be within 8-15): $val";
    }

    return;
}

sub _deflate_to_string {
    my (%args) = @_;

    my @params;

    my $indicated_cmwb;

    for my $argname (%args) {
        my $val = $args{$argname};
        next if !defined $val;

        if ($argname eq 'local_context_mode') {
            if ($val eq 'no_takeover') {
                push @params, 'client-no-context-takeover';
            }
            elsif ($val ne 'takeover') {
                Carp::croak "Bad “$argname”: $val";
            }
        }
        elsif ($argname eq 'peer_context_mode') {
            if ($val eq 'no_takeover') {
                push @params, 'server-no-context-takeover';
            }
            elsif ($val ne 'takeover') {
                Carp::croak "Bad “$argname”: $val";
            }
        }
        elsif ($argname eq 'local_max_window_bits') {
            _validate_deflate_max_window_bits($argname, $val);

            $indicated_cmwb = 1;

            push @params, "client-max-window-bits=$val";
        }
        elsif ($argname eq 'peer_max_window_bits') {
            _validate_deflate_max_window_bits($argname, $val);

            push @params, "server-max-window-bits=$val";
        }
        else {
            Carp::croak "Bad deflate arg: $argname";
        }
    }

    # Always announce support for this:
    push @params, 'client-max-window-bits' if !$indicated_cmwb;

    return join( '; ', 'permessage-deflate', @params );
}

sub _croak_bad_compression {
    my $name = shift;

    Carp::croak("Unknown compression name: $name");
}

sub _compression_to_ext {
    my ($comp_in) = @_;

    my @exts;

    if (defined $comp_in) {
        if (my $reftype = ref $comp_in) {
            if ('ARRAY' ne $reftype) {
                Carp::croak("`compression` must be a string or arrayref, not $comp_in");
            }

            for (my $a = 0; $a < @$comp_in; $a++) {
                my $extname = $comp_in->[$a] or Carp::croak('Missing `compression` item!');

                if ($extname eq 'deflate') {
                    my $next = $comp_in->[1 + $a];
                    if ($next && 'HASH' eq ref $next) {
                        $a++;
                        push @exts, _deflate_to_string(%$next);
                    }
                }
                else {
                    _croak_bad_compression($extname);
                }
            }
        }
        elsif ($comp_in eq 'deflate') {
            push @exts, [ deflate => _deflate_to_string() ];
        }
        else {
            _croak_bad_compression($comp_in);
        }
    }
    elsif (Net::Libwebsockets::HAS_PMD) {
        push @exts, [ deflate => _deflate_to_string() ];
    }

    if (@exts && !Net::Libwebsockets::HAS_PMD) {
        Carp::croak "This Libwebsockets lacks WebSocket compression support";
    }

    return \@exts;
}

sub _validate_uint {
    my ($name, $specimen) = @_;

    if ($specimen =~ tr<0-9><>c) {
        die "Bad “$name”: $specimen\n";
    }

    return;
}

sub _get_loop_obj {
    my ($event) = @_;

    my @args;

    if ('ARRAY' eq ref $event) {
        ($event, @args) = @$event;
    }

    require "Net/Libwebsockets/Loop/$event.pm";
    my $event_ns = "Net::Libwebsockets::Loop::$event";

    return $event_ns->new(@args);
}

1;
