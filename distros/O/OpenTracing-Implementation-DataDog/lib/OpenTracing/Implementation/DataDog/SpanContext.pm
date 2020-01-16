package OpenTracing::Implementation::DataDog::SpanContext;

=head1 NAME

OpenTracing::Implementation::DataDog::SpanContext - Keep track of traces

=head1 SYNOPSIS

    use aliased OpenTracing::Implementation::DataDog::SpanContext;
    
    my $span_context = SpanContext->new(
        service_name  => "MyFancyService",
        service_type  => "web",
        resource_name => "/clients/{client_id}/contactdetails",
    );
    #
    # please do not add parameter values in the resource,
    # use tags instead, like:
    # $span->set_tag( client_id => $request->query_params('client_id') )

=cut

use Moo;

with 'OpenTracing::Role::SpanContext';

use OpenTracing::Implementation::DataDog::Utils qw/random_64bit_int/;

use Types::Standard qw/Enum Str/;



has trace_id => (
    is              => 'ro',
    default         => sub { random_64bit_int() },
);



has service_name => (
    is              => 'ro',
    required        => 1,
    isa             => Str,
);



has service_type => (
    is              => 'ro',
    default         => 'custom',
    isa             => Enum[qw/web db cache custom/],
);



has resource_name => (
    is              => 'ro',
    isa             => Str,
    required        => 1,
);



=head1 CONSTRUCTORS



=head2 new

    my $span_context = SpanContext->new(
        service_name  => "MyFancyService",
        resource_name => "/clients/{client_id}/contactdetails",
        baggage_items => { $key => $value, .. },
    );

Creates a new SpanContext object;



=head1 ATTRIBUTES



=head2 trace_id

=head2 service_name

=head2 service_type

=head2 resource_name



=cut

1;
