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



our $VERSION = 'v0.43.2';

use English;

use Moo;
use MooX::Attribute::ENV;
use MooX::Should;

use Carp;
use HTTP::Request ();
use JSON::MaybeXS qw(JSON);
use LWP::UserAgent;
use PerlX::Maybe qw/maybe provided/;
use Types::Standard qw/Enum HasMethods/;

use OpenTracing::Implementation::DataDog::Utils qw(
    nano_seconds
);



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
    handles => { send_http_request => 'request' },
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
C<localhost> or the value of either C<DD_HOST> or C<DD_AGENT_HOST> environment
variable if set.

=cut

has host => (
    is      => 'ro',
    env_key => [ 'DD_HOST', 'DD_AGENT_HOST' ],
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

=head2 C<env>

The environment name to pass to the agent. By default, no environment is passed.

=cut

has env => (
    is      => 'ro',
    env_key => 'DD_ENV',
    default => undef,
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



has uri => (
    is => 'lazy',
    init_arg => undef,
);

sub _build_uri {
    my $self = shift;
    
    return "$self->{ scheme }://$self->{ host }:$self->{ port }/$self->{ path }"
}
#
# URI::Template is a nicer solution for this and more dynamic


has _json_encoder => (
    is              => 'lazy',
    init_arg        => undef,
    handles         => { json_encode => 'encode' },
);

sub _build__json_encoder {
    JSON()->new->utf8->canonical->pretty
}
#
# I just love readable and consistant JSONs



=head1 DELEGATED INSTANCE METHODS

The following method(s) are required by the L<DataDog::Tracer|
OpenTracing::Implementation::DataDog::Tracer>:

=cut



=head2 C<send_span>

This method gets called by the L<DataDog::Tracer|
OpenTracing::Implementation::DataDog::Tracer> to send a L<Span> with its
specific L<DataDog::SpanContext|OpenTracing::Implementation::DataDog::Tracer>.

This will typically get called during C<on_finish>.

=head3 Required Positional Arguments

=over

=item C<$span>

A L<OpenTracing Span|OpenTracing::Interface::Span> compliant object, that will
be serialised (using L<to_struct> and converted to JSON).

=back

=head3 Returns

A boolean, that comes from L<< C<is_succes>|HTTP::Response#$r->is_success >>.

=cut

sub send_span {
    my $self = shift;
    my $span = shift;
    
    my $data = $self->to_struct( $span );
    
    my $resp = $self->http_post_struct_as_json( [[ $data ]] );
    
    return $resp->is_success
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

=item C<name>

=item C<start>

=item C<duration>

=item C<parent_id> (optional)

=item C<error> (TODO)

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
        maybe
        env => $self->env,

        $span->get_tags,
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
        
        name      => $span->get_operation_name,
        start     => nano_seconds( $span->start_time() ),
        duration  => nano_seconds( $span->duration() ),
        
        maybe
        parent_id => $span->get_parent_span_id(),
        
#       error     => ... ,
        
        provided %meta_data,
        meta      => { %meta_data },
        
#       metrics   => ... ,
    };
    
    # TODO: use Hash::Ordered, so we can control what will be the first item in
    #       the long string of JSON text. But this needs investigation on how
    #       this behaves with JSON
    
    return $data
}



sub http_post_struct_as_json {
    my $self = shift;
    my $struct = shift;
    
    my $encoded_data = $self->json_encode($struct);
    do { warn "$encoded_data\n" }
        if $ENV{OPENTRACING_DEBUG};
    
    
    my $header = [
        'Content-Type'                  => 'application/json; charset=UTF-8',
        'Datadog-Meta-Lang'             => 'perl',
        'Datadog-Meta-Lang-Interpreter' => $EXECUTABLE_NAME,
        'Datadog-Meta-Lang-Version'     => $PERL_VERSION->stringify,
        'Datadog-Meta-Tracer-Version'   => $VERSION,
        'X-Datadog-Trace-Count'         => scalar @{$struct->[0]},
    ];
    
    my $rqst = HTTP::Request->new( 'POST', $self->uri, $header, $encoded_data );
        
    my $resp = $self->send_http_request( $rqst );
    
    return $resp;
}



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

1;
