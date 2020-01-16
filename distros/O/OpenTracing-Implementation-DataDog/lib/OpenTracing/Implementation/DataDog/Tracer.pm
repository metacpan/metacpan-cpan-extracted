package OpenTracing::Implementation::DataDog::Tracer;

use strict;
use warnings;

=head1 NAME

OpenTracing::Implementation::DataDog::Tracer - Keep track of traces

=head1 SYNOPSIS

    use aliased 'OpenTracing::Implementation::DataDog::Tracer';
    use aliased 'OpenTracing::Implementation::DataDog::Agent';
    use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
    
    my $TRACER = Tracer->new(
        agent => Agent->new(),
        scope_manager->ScopeManager->new(),
    );

and later

    sub foo {
        
        my $scope = $TRACER->start_active_span( Foo => %options );
        
        ...
        
    } # $scope runs out of scope and gets destroyed ...

=cut

use syntax 'maybe';

use Moo;

with 'OpenTracing::Role::Tracer';

use aliased 'OpenTracing::Implementation::DataDog::Span';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';
use aliased 'OpenTracing::Implementation::DataDog::Agent';
use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';

use Ref::Util qw/is_plain_hashref/;
use Types::Standard qw/HashRef InstanceOf Maybe Object/;

has agent => (
    is          => 'lazy',
    isa         => Object,
    handles     => [qw/send_span/],
    coerce
    => sub { is_plain_hashref $_[0] ? Agent->new( %{$_[0]} ) : $_[0] },
    default     => sub { {} },
);


has default_context => (
    is          => 'lazy',
    isa
    => Maybe[InstanceOf['OpenTracing::Implementation::DataDog::SpanContext']],
    coerce
    => sub { is_plain_hashref $_[0] ? SpanContext->new( %{$_[0]} ) : $_[0] },
    default
    => sub { { service_name => "????", resource_name => "????" } },
    reader      => 'get_default_context',
    writer      => 'set_default_context',
);



sub extract_context { $_[0]->get_default_context() }



sub inject_context { ... }



sub build_span {
    my $self = shift;
    my %opts = @_;
    
    my $span = Span->new(
             
        operation_name  => $opts{ operation_name },
        
        child_of        => $opts{ child_of },
        
        maybe
        start_time      => $opts{ start_time },
        
        maybe
        tags            => $opts{ tags },
        
        context         => $opts{ context },
        
        on_DEMOLISH     => sub {
            my $span = shift;
            $self->send_span( $span )
        },
        
    );
    
    return $span
}



sub _build_scope_manager {
    my $self = shift;
    
    return ScopeManager->new( @_ )
}

1;

