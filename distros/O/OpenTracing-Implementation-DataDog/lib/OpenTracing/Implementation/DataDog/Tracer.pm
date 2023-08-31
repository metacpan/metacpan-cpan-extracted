package OpenTracing::Implementation::DataDog::Tracer;

use strict;
use warnings;


our $VERSION = 'v0.47.0';

=head1 NAME

OpenTracing::Implementation::DataDog::Tracer - Keep track of traces

=head1 SYNOPSIS

    use aliased 'OpenTracing::Implementation::DataDog::Tracer';
    use aliased 'OpenTracing::Implementation::DataDog::Client';
    use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
    
    my $TRACER = Tracer->new(
        client => Client->new(),
    );

and later

    sub foo {
        
        my $scope = $TRACER->start_active_span( 'Operation Name' => %options );
        
        ...
        
        $scope->close;
        
        return $foo
    }

=cut

use syntax 'maybe';

use Moo;
use MooX::Should;

with 'OpenTracing::Role::Tracer';

use aliased 'OpenTracing::Implementation::DataDog::Client';
use aliased 'OpenTracing::Implementation::DataDog::HTTPPropagator';
use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
use aliased 'OpenTracing::Implementation::DataDog::Span';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Hash::Merge;
use Ref::Util qw/is_plain_hashref/;
use Types::Standard qw/Object Str/;



=head1 DESCRIPTION

This is a L<OpenTracing SpanContext|OpenTracing::Interface::SpanContext>
compliant implementation with DataDog specific extentions

=cut



=head1 EXTENDED ATTRIBUTES

=cut



=head2 C<scope_manager>

A L<OpenTracing::Types::ScopeManger> that now defaults to a
L<DataDog::ScopeManger|OpenTracing::Implementation::DataDog::ScopeManager>

=cut

has '+scope_manager' => (
    default => sub { ScopeManager->new },
);



=head1 DATADOG SPECIFIC ATTRIBUTES

=cut



=head2 C<client>

A client that has a C<send_span> method that will get called on a `on_finish`.

See L<DataDog::Client|OpenTracing::Implementation::DataDog::Client> for more.

It also accepts a plain hash refference with key-value pairs suitable to
construct a client object.

=cut

has client => (
    is          => 'lazy',
    should      => Object,
    handles     => [qw/send_span/],
    coerce
    => sub { is_plain_hashref $_[0] ? Client->new( %{$_[0]} ) : $_[0] },
    default     => sub { {} }, # XXX this does not return an Object !!!
);



has default_resource_name => (
    is          => 'ro',
    should      => Str,
    predicate   => 1,
);



has default_service_name => (
    is          => 'ro',
    should      => Str,
    predicate   => 1,
);



has default_service_type => (
    is          => 'ro',
    should      => Str,
    predicate   => 1,
);



has default_environment => (
    is          => 'ro',
    should      => Str,
    predicate   => 1,
);



has default_hostname => (
    is          => 'ro',
    should      => Str,
    predicate   => 1,
);



has default_version => (
    is          => 'ro',
    should      => Str,
    predicate   => 1,
);

has '_http_propagator' => (
    is      => 'ro',
    default => sub { HTTPPropagator->new },
);



sub build_span {
    my $self = shift;
    my %opts = @_;
    
    my $span = Span->new(
        
        operation_name  => $opts{ operation_name },
        
        maybe
        child_of        => $opts{ child_of },
        
        maybe
        start_time      => $opts{ start_time },
        
        maybe
        tags            => $opts{ tags },
        
        context         => $opts{ context },
        
        on_finish     => sub {
            my $span = shift;
            $self->send_span( $span )
        },
        
    );
    
    return $span
}



sub build_context {
    my $self = shift;
    my %opts = @_;
    
    my $resource_name = delete $opts{ resource_name }
        || $self->default_resource_name;
    
    my $service_name  = delete $opts{ service_name }
        || $self->default_service_name;
    
    my $service_type  = delete $opts{ service_type }
        || $self->default_service_type;
    
    my $environment   = delete $opts{ environment }
        || $self->default_environment;
    
    my $hostname   = delete $opts{ hostname }
        || $self->default_hostname;
    
    my $version   = delete $opts{ version }
        || $self->default_version;
    
    my $span_context = SpanContext->new(
        
        %opts,
        
        resource_name   => $resource_name,
        
        maybe
        service_name    => $service_name,
        
        maybe
        service_type    => $service_type,
        
        maybe
        environment     => $environment,
        
        maybe
        hostname        => $hostname,
        
        maybe
        version         => $version,
        
    );
    
    return $span_context
}



sub inject_context_into_array_reference  { return $_[1] } # $carrier



sub inject_context_into_hash_reference   {
    my $self = shift;
    my $carrier = shift;
    my $context = shift;
    
    return Hash::Merge->new('RIGHT_PRECEDENT')->merge(
        $carrier,
        {
            opentracing_context => {
                trace_id      => $context->trace_id,
                span_id       => $context->span_id,
                resource      => $context->get_resource_name,
                service       => $context->get_service_name,
                maybe
                type          => $context->get_service_type,
                maybe
                environment   => $context->get_environment,
                maybe
                hostname      => $context->get_hostname,
            }
            
        }
    )
}



sub inject_context_into_http_headers {
    my ($self, $carrier, $context) = @_;
    $carrier = $carrier->clone;

    $self->_http_propagator->inject($carrier, $context);

    return $carrier;
}

sub extract_context_from_array_reference { return undef }
sub extract_context_from_hash_reference  { return undef }

sub extract_context_from_http_headers {
    my ($self, $carrier) = @_;
    my ($trace_id, $span_id) = $self->_http_propagator->extract($carrier);
    return unless defined $trace_id and defined $span_id;

    return $self->build_context()
                ->with_trace_id($trace_id)
                ->with_span_id($span_id);
}

=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<OpenTracing::Role::Tracer>

Role for OpenTracing Implementations.

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
