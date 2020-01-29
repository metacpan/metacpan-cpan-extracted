package OpenTracing::Role::Tracer;

=head1 NAME

OpenTracing::Role::Tracer - Role for OpenTracin implementations.

=head1 SYNOPSIS

    package OpenTracing::Implementation::MyBackendService::Tracer;
    
    use Moo;
    
    sub start_active_span { ... };
    
    sub start_span { ... };
    
    ...
    
    with 'OpenTracing::Role::Tracer';
    
    1;

=cut

use Moo::Role;

use Carp;
use Try::Tiny;
use Types::Standard qw/Object/;



=head1 DESCRIPTION

This is a base-class for OpenTracing implenetations that are compliant with the
L<OpenTracing::Interface>.

=cut



has scope_manager => (
    is              => 'lazy',
    isa             => Object,
    reader          => 'get_scope_manager',
);



requires '_build_scope_manager';

requires 'build_span';

requires 'extract_context';

requires 'inject_context';



sub get_active_span {
    my $self = shift;
    
    my $span = try {
        $self->get_scope_manager->get_active_scope->get_span
    } catch {
        return undef
    };
    
    return $span
}
#
# this is not really a good design but so convenient.



# this is not an OpenTracing API requirement
#
sub get_active_span_context {
    my $self = shift;
    
    my $span_context = try {
        $self->get_active_span->get_context
    } catch {
        return undef
    };
    
    return $span_context
}



sub start_active_span {
    my $self = shift;
    my $operation_name = shift
        or croak "Missing required operation_name";
    my $opts = { @_ };
    
    # remove the `finish_span_on_close` option, which is for this method only! 
    my $finish_span_on_close = 
        exists( $opts->{ finish_span_on_close } ) ?
            !! delete $opts->{ finish_span_on_close }
            : !undef
    ; # use 'truthness' of param if provided, or set to 'true' otherwise
    
    my $span = $self->start_span( $operation_name => %$opts );
    
    my $scope_manager = $self->get_scope_manager();
    
    my $scope = $scope_manager->activate_span( $span,
        finish_span_on_close => $finish_span_on_close
    );
    
    return $scope
}



sub start_span {
    my $self = shift;
    my $operation_name = shift
        or croak "Missing required operation_name";
    my $opts = { @_ };
    
    my $start_time         = delete $opts->{ start_time };
    my $ignore_active_span = delete $opts->{ ignore_active_span };
    my $child_of           = delete $opts->{ child_of };
    my $tags               = delete $opts->{ tags };
    
    $child_of //= $self->get_active_span()
        unless $ignore_active_span;
    
#   $child_of->does(') ?
    
    my $context =
        defined $child_of
        && 
        $child_of->does('OpenTracing::Interface::SpanContext')
        ?
        $child_of : $self->get_active_span_context();
    
    my $span = $self->build_span(
        operation_name => $operation_name,
        child_of       => $child_of,
        start_time     => $start_time,
        tags           => $tags,
        context        => $context,
    );
    
    return $span
}



=head1 REQUIRES

The followin must be implemented by consuming class

=cut



=head2 build_span

=cut

##### requires 'build_span';
#
# $self->build_span(
#     operartion_name => $operation_name,
#     start_time      => $start_time,
#     tags            => \@tags,
#     context         => $context,
# );



BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::Tracer'
        if $ENV{OPENTRACING_INTERFACE};
}



1;