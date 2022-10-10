package Net::HTTP2::Client::Connection;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::Client::Connection - Base class for individual HTTP/2
client connection

=head1 SYNOPSIS

See:

=over

=item * L<Net::HTTP2::Client::Connection::Mojo>

=item * L<Net::HTTP2::Client::Connection::IOAsync>

=item * L<Net::HTTP2::Client::Connection::AnyEvent>

=back

=head1 DESCRIPTION

This implements a non-blocking, B<non-redirecting> HTTP/2 client.
It’s a base class; the actual class you’ll use will depend on your
event loop interface (see L</SYNOPSIS>).

If you want a full-featured client (that honors redirections),
see L<Net::HTT2::Client>.

=head1 CONNECTION LONGEVITY

TCP connections are kept open as long as instances of this class live.

=head1 HTTP REDIRECTION

This class’s design would facilitate HTTP redirects only in the case
where the target of the redirect is the same server that answers the
initial request. (e.g., we could honor
C<Location: https://same.server/some/other/path> or
C<Location: /some/other/path>, but not
C<Location: https://some.other.server/foo>.)

To avoid that inconsistency, this class purposely omits HTTP redirection.
See L<Net::HTTP2::UserAgent> for an interface that implements redirection.

=cut

#----------------------------------------------------------------------

use Carp ();
use Scalar::Util ();

use Protocol::HTTP2::Client ();
use Protocol::HTTP2::Constants ();

use Net::HTTP2::Constants ();
use Net::HTTP2::X ();
use Net::HTTP2::Response ();
use Net::HTTP2::PartialResponse ();
use Net::HTTP2::RejectorRegistry ();

# Lazy-load so that Mojo doesn’t load Promise::ES6.
use constant _PROMISE_CLASS => 'Promise::ES6';

use constant {
    _DEBUG => 1,

    _ALPN_PROTOS => ['h2'],
};

use constant _INIT_OPTS => (
    'port',
    'tls_verify',
);

my %TLS_VERIFY = (
    none => 0,
    peer => 1,
);

sub _parse_args {
    my $class = shift;
    my $peer = shift;

    my %raw_opts = @_;

    my %opts = map { $_ => delete $raw_opts{$_} } $class->_INIT_OPTS();

    if (my @extra = sort keys %raw_opts) {
        Carp::croak "Unknown: @extra";
    }

    my @extra_args;

    my $port = delete $opts{'port'};

    if (my $tls_verify = delete $opts{'tls_verify'}) {
        my $val = $TLS_VERIFY{$tls_verify};
        if (!defined $val) {
            Carp::croak "Bad `tls_verify`: $tls_verify";
        }

        push @extra_args, tls_verify_yn => $val;
    }

    push @extra_args, $class->_parse_event_args(%opts);

    return ( $peer, $port, @extra_args );
}

use constant _parse_event_args => ();

#----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new( $HOSTNAME_OR_IP, %OPTS )

Instantiates I<CLASS>.

%OPTS will depend on the I<CLASS>, but can always include:

=over

=item * C<port> - The TCP port to connect to. Defaults to 443.

=item * C<tls_verify> - Either C<peer> (default) or C<none>.

=back

=cut

sub new {
    my ($class, @args) = @_;

    # TODO: Allow special options to be passed for TLS,
    # e.g., verification options.

    my ($host, $port, @extra_args) = $class->_parse_args(@args);

    $port ||= Net::HTTP2::Constants::HTTPS_PORT;

    my $rejectors_obj = Net::HTTP2::RejectorRegistry->new();

    my $self = bless {
        host => $host,
        port => $port,

        pid => $$,

        rejectors => $rejectors_obj,

        @extra_args,
    }, $class;

    my @client_args = (
        keepalive => 1,

        # H2 server push is, as of 2022, rarely used,
        # so we won’t support it here.

        on_error => sub {
            my $errnum = shift;

            $rejectors_obj->reject_all(
                Net::HTTP2::X->create('HTTP2', $errnum),
            );
        },
    );

    if (_DEBUG) {
        push @client_args, (
            on_change_state => sub {
                my ( $stream_id, $previous_state, $current_state ) = @_;
                _debug( change_State => @_ );
            },
        );
    }

    $self->{'h2'} = Protocol::HTTP2::Client->new(@client_args);

    return $self;
}

=head2 promise($result) = I<OBJ>->request( $METHOD, $PATH_AND_QUERY, %OPTS )

Sends an HTTP/2 request.

Returns a promise (an instance of <Promise::ES6>, unless
otherwise noted in the subclass) that resolves to a L<Net::HTTP2::Response>
instance.

%OPTS can be:

=over

=item * C<headers> - Request headers, as in L<HTTP::Tiny>’s C<request()>.

=item * C<content> - Request content, as in L<HTTP::Tiny>’s C<request()>.

=item * C<on_data> - A code reference that fires as each chunk of the
HTTP response arrives. The code reference always receives a
L<Net::HTTP2::PartialResponse> instance.

=back

On failure (I<NOT> including valid HTTP responses!), the promise rejects
with an instance of an appropriate L<Net::HTTP2::X::Base> class,
e.g., L<Net::HTTP2::X::HTTP2>.

=cut

sub request {
    my ($self, $method, $path_query, %opts) = @_;

    my @headers;

    if ($opts{'headers'}) {
        for my $name (keys %{$opts{'headers'}}) {
            my $val = $opts{'headers'}{$name};

            if ('ARRAY' eq ref $val) {
                push @headers, $name => $_ for @$val;
            }
            else {
                push @headers, $name => $val;
            }
        }
    }

    my @extra_args;

    if (defined $opts{'content'}) {
        push @extra_args, data => $opts{'content'};
    }

    if (my $data_cr = $opts{'on_data'}) {
        push @extra_args, (
            on_headers => sub {
                my $canceled;

                $data_cr->( Net::HTTP2::PartialResponse->new(\$canceled, $_[0], q<>) );

                return !$canceled || undef;
            },
            on_data => sub {
                my $canceled;

                $data_cr->( Net::HTTP2::PartialResponse->new(\$canceled, @_[1, 0]) );

                return !$canceled || undef;
            },
        );
    }

    my $rejectors_obj = $self->{'rejectors'};

    my $rejector_str;

    return $self->_get_promise_class()->new( sub {
        my ($res, $rej) = @_;

        $rejector_str = $rejectors_obj->add($rej);

        $self->_start_io_if_needed(@{$self}{'host', 'port', 'h2'});

        my $weak_h2 = $self->{'h2'};
        Scalar::Util::weaken($weak_h2);

        my $authty = $self->{'host'};

        # Some services act differently if :443 is postfixed unnecessarily.
        # For example, as of this writing perl.org will give a 404 rather
        # than the redirect to www.perl.org that it should give.
        #
        $authty .= ":$self->{'port'}" if $self->{'port'} != Net::HTTP2::Constants::HTTPS_PORT;

        $self->{'h2'}->request(
            ':scheme' => 'https',
            ':authority' => $authty,
            ':path' => $path_query,
            ':method' => $method,

            headers => \@headers,

            on_done => sub {
                $res->( Net::HTTP2::Response->new(@_) );
            },

            on_error => sub {
                my $errnum = shift;
                $rej->( Net::HTTP2::X->create('HTTP2', $errnum) );
            },

            @extra_args,
        );

        $self->_send_pending_frames();
    } )->finally( sub {
        $rejectors_obj->remove($rejector_str);
    } );
}

# =head2 $obj = I<OBJ>->close()
#
# Tells the server we are ending the connection. Automatically called
# when I<OBJ> is DESTROY()ed, so you usually don’t need to call this.
#
# Returns a promise that resolves when the HTTP/2 GOAWAY frame is sent.
#
# =cut
#
# sub close {
#     my ($self) = @_;
#
#     if ($self->{'_close_called'}) {
#         Carp::croak "Duplicate close() call\n";
#     }
#
#     $self->{'_close_called'} = 1;
#
#     my $close_cr = sub {
#         my $res = shift;
#
#         $self->{'h2'}->close();
#
#         $self->_send_pending_frames($res || ());
#     };
#
#     if (defined wantarray) {
#         my $rejector_str;
#
#         my $rejectors_obj = $self->{'rejectors'};
#
#         return $self->{'_close_p'} ||= $self->_get_promise_class()->new( sub {
#             my ($res, $rej) = @_;
#
#             $rejector_str = $rejectors_obj->add($rej);
#
#             $close_cr->($res);
#         } )->finally( sub {
#             $rejectors_obj->remove($rejector_str);
#         } );
#     }
#     else {
#         $close_cr->();
#     }
# }

#----------------------------------------------------------------------

sub DESTROY {
    my $self = shift;

    $self->_h2_close();

    if (${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT') {
        if ($self->{'pid'} == $$) {
            warn "$self: DESTROY() at global destruction; memory leak likely!\n";
        }
    }
}

sub _h2_close {
    my $self = shift;

    $self->{'h2'}->close();
    $self->_send_pending_frames();
}

sub _on_stream_error {
    my ($self, $err) = @_;

    my $rejectors = $self->{'rejectors'};

    if ($rejectors->count()) {
        $rejectors->reject_all($err);
    }
    else {
        warn $err;
    }
}

sub _on_stream_close {
    my $self = shift;

    my $rejectors = $self->{'rejectors'};

    if ($rejectors->count()) {
        $rejectors->reject_all("Unexpected close of TCP stream!");
    }
    elsif (!$self->{'_close_called'}) {
        print "TCP peer closed\n";
    }
}

sub _send_pending_frames {
    my ($self, $cb) = @_;

    if ($cb) {
        my @frames;

        while (my $frame = $self->{'h2'}->next_frame()) {
            push @frames, $frame;
        }

        if (@frames) {
            my $last_frame = pop @frames;

            $self->_write_frame($_) for @frames;
            $self->_write_frame($last_frame, $cb);
        }
    }
    else {
        while (my $frame = $self->{'h2'}->next_frame()) {
            $self->_write_frame($frame);
        }
    }

    return;
}

sub _debug {
    print STDERR "DEBUG: @_\n" if _DEBUG;
}

sub _get_promise_class {
    my ($self) = @_;

    my $promise_class = $self->_PROMISE_CLASS();

    local ($!, $@);
    eval "require $promise_class; 1" || die if !$promise_class->can('new');

    return $promise_class;
}

1;
