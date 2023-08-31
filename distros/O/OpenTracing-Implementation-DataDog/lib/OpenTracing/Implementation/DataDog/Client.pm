package OpenTracing::Implementation::DataDog::Client;

=head1 NAME

OpenTracing::Implementation::DataDog::Client - A Client that sends off the spans

=head1 SYNOPSIS

    use alias OpenTracing::Implementation::DataDog::Client;
    
    my $datadog_client = ->new(
        http_user_agent => LWP::UserAgent->new();
        host            => 'localhost',
        port            => '8126',
        path            => 'v0.3/traces',
    ); # these are defaults

and later:

    $datadog_client->send_span( $span );

=cut



=head1 DESCRIPTION

The main responsabillity of this C<Client> is to provide the C<send_span>
method, that will send the data to the local running DataDog agent.

It does this by calling L<to_struct> that massages the generic OpenTracing data,
like C<baggage_items> from L<SpanContext> and C<tags> from C<Span>, together
with the DataDog specific data like C<resource_name>.

This structure will be send of as a JSON string to the local installed DataDog
agent.

=cut



our $VERSION = 'v0.47.0';

use English;

use Moo;
use Sub::HandlesVia;
#   XXX Order matters: Sub::HandlesVia::Manual::WithMoo - Potential load order
use MooX::Attribute::ENV;
use MooX::ProtectedAttributes;
use MooX::Should;

use Carp;
use HTTP::Request ();
use JSON::MaybeXS qw(JSON);
use LWP::UserAgent;
use PerlX::Maybe qw/maybe provided/;
use Regexp::Common qw/URI/;
use Types::Standard qw/ArrayRef Bool Enum HasMethods Maybe Str/;
use Types::Common::Numeric qw/IntRange/;

use OpenTracing::Implementation::DataDog::Utils qw(
    nano_seconds
);

use constant MAX_SPANS => 20_000; # this is just an arbitrary, hardcoded number



=head1 OPTIONAL ATTRIBUTES

The attributes below can be set during instantiation, but none are required and
have sensible defaults, that may actually play nice with known DataDog
environment variables

=cut



=head2 C<http_user_agent>

A HTTP User Agent that connects to the locally running DataDog agent. This will
default to a L<LWP::UserAgent>, but any User Agent will suffice, as long as it
has a required delegate method C<request>, that takes a L<HTTP::Request> object
and returns a L<HTTP::Response> compliant response object.

=cut

has http_user_agent => (
    is => 'lazy',
    should => HasMethods[qw/request/],
    handles => { _send_http_request => 'request' },
);

sub _build_http_user_agent {
    return LWP::UserAgent->new( )
}



=head2 C<scheme>

The scheme being used, should be either C<http> or C<https>,
defaults to C<http>

=cut

has scheme => (
    is => 'ro',
    should => Enum[qw/http https/],
    default => 'http',
);



=head2 C<host>

The host-name where the DataDog agent is running, which defaults to
C<localhost> or the value of C<DD_AGENT_HOST> environment variable if set.

=cut

has host => (
    is      => 'ro',
    env_key => 'DD_AGENT_HOST',
    default => 'localhost',
);



=head2 C<port>

The port-number the DataDog agent is listening at, which defaults to C<8126> or
the value of the C<DD_TRACE_AGENT_PORT> environment variable if set.

=cut

has port => (
    is => 'ro',
    env_key => 'DD_TRACE_AGENT_PORT',
    default => '8126',
);



=head2 C<path>

The path the DataDog agent is expecting requests to come in, which defaults to
C<v0.3/traces>.

=cut

has path => (
    is => 'ro',
    default => 'v0.3/traces',
);
#
# maybe a 'version number' would be a better option ?



=head2 C<agent_url>

The complete URL the DataDog agent is listening at, and defaults to the value of
the C<DD_TRACE_AGENT_URL> environment variable if set. If this is set, it takes
precedence over any of the other settings.

=cut

has agent_url => (
    is => 'ro',
    env_key => 'DD_TRACE_AGENT_URL',
    should  => Maybe[Str->where( sub { _is_uri($_) } )],
);

=pod

NOTE: DataDog Agents can also listen to a UNiX socket, and one is suggested that
there is a C<unix:> URL. Fist of all, that is false, the C<unix:> scheme is just
non existent. It should be C<file:> instead. Secondly, this L<Client> just does
not support it, only C<http:> or C<https:>

=cut



has uri => (
    is => 'lazy',
    init_arg => undef,
);

sub _build_uri {
    my $self = shift;
    
    return
        $self->agent_url
        //
        "$self->{ scheme }://$self->{ host }:$self->{ port }/$self->{ path }"
}
#
# URI::Template is a nicer solution for this and more dynamic



protected_has _default_http_headers => (
    is          => 'lazy',
    isa         => ArrayRef,
    init_arg    => undef,
    handles_via => 'Array',
    handles     => {
        _default_http_headers_list => 'all',
    },
);

sub _build__default_http_headers {
    return [
        'Content-Type'                  => 'application/json; charset=UTF-8',
        'Datadog-Meta-Lang'             => 'perl',
        'Datadog-Meta-Lang-Interpreter' => $EXECUTABLE_NAME,
        'Datadog-Meta-Lang-Version'     => $PERL_VERSION->stringify,
        'Datadog-Meta-Tracer-Version'   => $VERSION,
    ]
}



has _json_encoder => (
    is              => 'lazy',
    init_arg        => undef,
    handles         => { _json_encode => 'encode' },
);

sub _build__json_encoder {
    JSON()->new->utf8->canonical->pretty->allow_bignum
}
#
# I just love readable and consistant JSONs



=head2 C<span_buffer_threshold>

This sets the size limit of the span buffer. When this number is reached, this
C<Client> will send off the buffered spans using the internal C<user_agent>.

This number can be set on instantiation, or will take it from the
C<DD_TRACE_PARTIAL_FLUSH_MIN_SPANS> environment variable. If nothing is set, it
defaults to 100.

The number can not be set to anything higher than 20_000.

If this number is C<0> (zero), spans will be sent with each call to
C<send_span>.

=cut

has span_buffer_threshold => (
    is      => 'rw',
    isa     => IntRange[ 0, MAX_SPANS ],
    env_key => 'DD_TRACE_PARTIAL_FLUSH_MIN_SPANS',
    default => 100,
);



protected_has _span_buffer => (
    is          => 'rw',
    isa         => ArrayRef,
    init_args   => undef,
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        _buffer_span         => 'push',
        _span_buffer_size    => 'count',
        _buffered_spans      => 'all',
        _empty_span_buffer   => 'clear',
    },
);



protected_has _client_halted => (
    is            => 'rw',
    isa           => Bool,
    reader        => '_has_client_halted',
    default       => 0,
    handles_via   => 'Bool',
    handles       => {
        _halt_client => 'set'
    },
);



=head1 DELEGATED INSTANCE METHODS

The following method(s) are required by the L<DataDog::Tracer|
OpenTracing::Implementation::DataDog::Tracer>:

=cut



=head2 C<send_span>

This method gets called by the L<DataDog::Tracer|
OpenTracing::Implementation::DataDog::Tracer> to send a L<Span> with its
specific L<DataDog::SpanContext|OpenTracing::Implementation::DataDog::SpanContext>.

This will typically get called during C<on_finish>.

=head3 Required Positional Arguments

=over

=item C<$span>

An L<OpenTracing Span|OpenTracing::Interface::Span> compliant object, that will
be serialised (using L<to_struct> and converted to JSON).

=back

=head3 Returns

=over

=item C<undef>

in case something went wrong during the HTTP-request or the client has been
halted in any previous call.

=item a positive int

indicating the number of collected spans, in case this client has only buffered
the span.

=item a negative int

indicating the number of flushed spans, in case the client has succesfully
flushed the spans collected in the buffer.

=back

=cut

sub send_span {
    my $self = shift;
    my $span = shift;
    
    return
        if $self->_has_client_halted();
    # do not add more spans to the buffer
    
    my $new_span_buffer_size = $self->_buffer_span($span);
    
    return $new_span_buffer_size
        unless ( $new_span_buffer_size // 0 ) > 0;
    # this should be the number of spans in the buffer, should not be undef or 0
    
    return $new_span_buffer_size
        unless $self->_should_flush_span_buffer();
    
    my $flushed = $self->_flush_span_buffer();
    
    return
        unless defined $flushed;
    
    return -$flushed
    
}



=head1 INSTANCE METHODS

=cut



=head2 C<to_struct>

Gather required data from a single span and its context, tags and baggage items.

=head3 Required Positional Arguments

=over

=item C<$span>

=back

=head3 Returns

a hashreference with the following keys:

=over

=item C<trace_id>

=item C<span_id>

=item C<resource>

=item C<service>

=item C<type> (optional)

=item C<env> (optional)

=item C<hostname> (optional)

=item C<name>

=item C<start>

=item C<duration>

=item C<parent_id> (optional)

=item C<error>

=item C<meta> (optional)

=item C<metrics>

=back

=head3 Notes

This data structure is specific for sending it through the DataDog agent and
therefore can not be a intance method of the DataDog::Span object.

=cut

sub to_struct {
    my $self = shift;
    my $span = shift;
    
    my $context = $span->get_context();
    
    my %meta_data = (
        _fixup_span_tags( $span->get_tags ),
        $context->get_baggage_items,
    );
    
    # fix issue with meta-data, values must be string!
    %meta_data =
        map { $_ => "$meta_data{$_}" } keys %meta_data
    if %meta_data;
    
    my $data = {
        trace_id  => $context->trace_id,
        span_id   => $context->span_id,
        resource  => $context->get_resource_name,
        service   => $context->get_service_name,
        
        maybe
        type      => $context->get_service_type,
        
        maybe
        env       => $context->get_environment,
        
        maybe
        hostname  => $context->get_hostname,
        
        maybe
        version   => $context->get_version,
        
        name      => $span->get_operation_name,
        start     => nano_seconds( $span->start_time() ),
        duration  => nano_seconds( $span->duration() ),
        
        maybe
        parent_id => $span->get_parent_span_id(),
        
        provided _is_with_errors( $span ),
        error     => 1,
        
        provided %meta_data,
        meta      => { %meta_data },
        
#       metrics   => ... ,
    };
    
    # TODO: use Hash::Ordered, so we can control what will be the first item in
    #       the long string of JSON text. But this needs investigation on how
    #       this behaves with JSON
    
    return $data
}



=head1 ENVIRONMENT VARIABLES

For configuring DataDog Tracing there is support for the folllowing environment
variables:



=head2 C<DD_AGENT_HOST>

Hostname for where to send traces to. If using a containerized environment,
configure this to be the host IP.

B<default:> C<localhost>



=head2 C<DD_TRACE_AGENT_PORT>

The port number the Agent is listening on for configured host. If the Agent
configuration sets receiver_port or C<DD_APM_RECEIVER_PORT> to something other
than the default B<8126>, then C<DD_TRACE_AGENT_PORT> or C<DD_TRACE_AGENT_URL>
must match it.

B<default:> C<8126>


=head2 C<DD_TRACE_AGENT_URL>

The URL to send traces to. If the Agent configuration sets receiver_port or
C<DD_APM_RECEIVER_PORT> to something other than the default B<8126>, then
C<DD_TRACE_AGENT_PORT> or C<DD_TRACE_AGENT_URL> must match it. The URL value can
start with C<http://> to connect B<using HTTP> or with C<unix://> to use a
B<Unix Domain Socket>.

When set this takes precedence over C<DD_AGENT_HOST> and C<DD_TRACE_AGENT_PORT>.

B<CAVEATE: > the C<unix:> scheme is non-exisitent, and is not supported with the
L<DataDog::Client|OpenTracing::Implementation::DataDog::Client>.



=head2 C<DD_TRACE_PARTIAL_FLUSH_MIN_SPANS>

Set a number of partial spans to flush on. Useful to reduce memory overhead when
dealing with heavy traffic or long running traces.

B<default:> 100



=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<DataDog Docs API Tracing|https://docs.datadoghq.com/api/v1/tracing/>

The DataDog B<Agent API> Documentation.

=item L<LWP::UserAgent>

Web user agent class

=item L<JSON::Maybe::XS>

Use L<Cpanel::JSON::XS> with a fallback to L<JSON::XS> and L<JSON::PP>

=item L<HTTP::Request>

HTTP style request message

=item L<HTTP::Response>

HTTP style response message

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2021, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut


# _fixup_span_tags
#
# rename and or remove key value pairs from standard OpenTracing to what
# DataDog expects to be send
#
sub _fixup_span_tags {
    my %tags = @_;
    
    my $error = delete $tags { error };
    
    $tags { 'error.type'    } = delete $tags{ 'error.kind' }
        if $error;
    
    $tags { 'error.message' } = delete $tags{ 'message' }
        if $error;
    
    return %tags;
}



# _flush_span_buffer
#
# Flushes the spans in the span buffer and send them off to the DataDog agent
# over HTTP.
#
# Returns the number off flushed spans or `undef` in case of an error.
#
sub _flush_span_buffer {
    my $self = shift;
    
    my @structs = map {$self->to_struct($_) } $self->_buffered_spans();
    
    my $resp = $self->_http_post_struct_as_json( [ \@structs ] )
        or return;
    
    $self->_empty_span_buffer();
    
    return scalar @structs;
}



# checks if there is an exisiting 'error' tag
#
sub _is_with_errors {
    my $span = shift;
    return exists { $span->get_tags() }->{ error }
}



# _is_uri
#
# Returns true if the given string matches an http(s) url
#
sub _is_uri {
    return $RE{URI}{HTTP}{-scheme => 'https?'}->matches(shift)
    # scheme must be specified, defaults to 'http:'
}



# _http_headers_with_trace_count
#
# Returns a list of HTTP Headers needed for DataDog
#
# This feature was originally added, so the Trace-Count could dynamically set
# per request. That was a design flaw, and now the count is hardcoded to '1',
# until we figured out how to send multiple spans.
#
sub _http_headers_with_trace_count {
    my $self = shift;
    my $count = shift;
    
    return (
        $self->_default_http_headers_list,
        
        maybe
        'X-Datadog-Trace-Count' => $count,
    )
}



# _http_post_struct_as_json
#
# Takes a given data structure and sends an HTTP POST request to the tracing
# agent.
#
# It is the caller's responsibility to generate the correct data structure!
#
# Maybe returns an HTTP::Response object, which may indicate a failure.
#
sub _http_post_struct_as_json {
    my $self = shift;
    my $struct = shift;
    
    return
        if $self->_has_client_halted();
    # this shouldn't be needed, but will happen on DEMOLISH & spans in buffer

    my $encoded_data = $self->_json_encode($struct);
    do { warn "$encoded_data\n" }
        if $ENV{OPENTRACING_DEBUG};
    
    my @headers = $self->_http_headers_with_trace_count( scalar @{$struct->[0]} );
    my $rqst = HTTP::Request->new( 'POST', $self->uri, \@headers, $encoded_data );
    
    my $resp = $self->_send_http_request( $rqst );
    if ( $resp->is_error ) {
        #
        # not interested in what the error actually has been, no matter what it
        # was, this client will be halted, be it an error in the data send (XXX)
        # or a problem with the recipient tracing agent.
        #
        $self->_halt_client();
        warn sprintf "DataDog::Client being halted due to an error [%s]\n",
            $resp->status_line;
        return;
    }
    
    return $resp;
}



# _last_buffered_span
#
# Returns the last span added to the buffer.
#
# nothing special, but just easier to read the code where it is used
#
sub _last_buffered_span {
    my $self = shift;
    
    return $self->_span_buffer->[-1]
}



# _should_flush_span_buffer
#
# Returns a 'Boolean'
#
# For obvious reasons, it should be flushed if the limit has been reached.
# But another reason is when the root-span has been just added. It is the first
# span being created, but it is therefor the last one being closed and send.
#
sub _should_flush_span_buffer {
    my $self = shift;
    
    return (
        $self->_last_buffered_span()->is_root_span
        or
        $self->_span_buffer_threshold_reached()
    );
}



# _span_buffer_threshold_reached
#
# Returns a 'Boolean', being 'true' once the limit has been reached
#
sub _span_buffer_threshold_reached {
    my $self = shift;
    
    return $self->_span_buffer_size >= $self->span_buffer_threshold
}



# DEMOLISH
#
# This should not happen, but just in case something went completely wrong, this
# will try to flush the buffered spans as a last resort.
#
sub DEMOLISH {
    my ($self) = @_;
    
    $self->_flush_span_buffer() if $self->_span_buffer_size(); # send leftovers
    
    return;
}

1;
