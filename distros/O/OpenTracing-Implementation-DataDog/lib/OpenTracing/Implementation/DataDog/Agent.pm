package OpenTracing::Implementation::DataDog::Agent;

=head1 NAME

OpenTracing::Implementation::DataDog::Agent - A Client that sends off the data

=head1 SYNOPSIS

    use alias OpenTracing::Implementation::DataDog::Agent;
    
    my $dd_agent = Agent->new(
        user_agent => LWP::UserAgent->new();
        host       => 'localhost',
        port       => '8126',
        path       => 'v0.3/traces',
    ); # these are defaults

and later:

    $dd_agent->send_span( $span );

=cut

use Moo;
use MooX::Attribute::ENV;

use Carp;
use HTTP::Request ();
use JSON::MaybeXS qw(JSON);
use LWP::UserAgent;
use PerlX::Maybe qw/maybe provided/;
use Types::Standard qw/HasMethods/;



has user_agent => (
    is => 'lazy',
    isa => HasMethods[qw/request/],
);

sub _build_user_agent {
    return LWP::UserAgent->new( )
}



has host => (
    is => 'ro',
    env_key => 'DD_AGENT_HOST',
    default => 'localhost',
);



has port => (
    is => 'ro',
    env_key => 'DD_TRACE_AGENT_PORT',
    default => '8126',
);



has path => (
    is => 'ro',
    default => 'v0.3/traces',
);



has uri => (
    is => 'lazy',
    init_arg => undef,
);

sub _build_uri {
    my $self = shift;
    
    return "http://$self->{ host }:$self->{ port }/$self->{ path }"
}



has _json_encoder => (
    is              => 'lazy',
    init_arg        => undef,
    handles         => { json_encode => 'encode' },
);

sub _build__json_encoder {
    JSON()->new->utf8->canonical->pretty
}



sub send_span {
    my $self = shift;
    my $span = shift;
    
    my $data = __PACKAGE__->to_struct( $span );
    
    my $resp = $self->_http_post_struct_as_json( [[ $data ]] );
    
    return $resp->is_success
}



# to_struct
#
# Gather required data from the span and it's context, tags and baggage items.
# this data structure is specific for sending it through the DataDog agent and
# therefore can not be a intance method of the DataDog::Span object.
#
sub to_struct {
    my $class = shift;
    my $span = shift;
    
    my $context = $span->get_context();
    
    my $meta_data = {
        $span->get_tags,
        $context->get_baggage_items,
    };
    
    my $data = {
        trace_id  => $context->trace_id,
        span_id   => $span->span_id,
        resource  => $context->resource_name,
        service   => $context->service_name,
        
        maybe
        type      => $context->service_type,
        
        name      => $span->operation_name,
        start     => $span->nano_seconds_start_time(),
        duration  => $span->nano_seconds_duration(),
        
        maybe
        parent_id => $span->parent_span_id(),
        
#       error     => ... ,
        
        provided %$meta_data,
        meta      => $meta_data,
        
#       metrics   => ... ,
    };
    
    # TODO: use Hash::Ordered, so we can control what will be the first item in
    #       the long string of JSON text. But this needs investigation on how
    #       this behaves with JSON
    
    return $data
}



sub _http_post_struct_as_json {
    my $self = shift;
    my $struct = shift;
    
    my $encoded_data = $self->json_encode($struct);
    do { warn "$encoded_data\n" }
        if $ENV{OPENTRACING_DEBUG};
    
    
    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];
    my $rqst = HTTP::Request->new( 'POST', $self->uri, $header, $encoded_data );
        
    my $resp = $self->user_agent->request( $rqst );
    
    return $resp;
}



1;
