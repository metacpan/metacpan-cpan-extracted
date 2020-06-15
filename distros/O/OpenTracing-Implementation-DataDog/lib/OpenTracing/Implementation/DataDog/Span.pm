package OpenTracing::Implementation::DataDog::Span;

our $VERSION = 'v0.30.1';

use syntax 'maybe';

use Moo;

with 'OpenTracing::Role::Span';

use OpenTracing::Implementation::DataDog::Utils qw(
    random_64bit_int
    nano_seconds
);

use Types::Standard qw/CodeRef Object/;



has span_id => (
    is => 'ro',
    init_arg => undef,
    default => sub{ random_64bit_int() }
);



has child_of => (
    is => 'ro',
    isa =>Object, # does Span or does SpanContext
    required => 1,
);



has on_DEMOLISH => (
    is              => 'ro',
    isa             => CodeRef,
    default         => sub { sub { } }
);



sub parent_span_id {
    my $self = shift;
    
    my $parent = $self->{ child_of };
    return unless $parent->does('OpenTracing::Role::Span');
    
    return $parent->span_id
}
#
# This may not be the right way to implement it, for the `child_of` attribute
# may not be such a good idea, maybe it should use references, but not sure how
# those are used





sub nano_seconds_start_time { nano_seconds( $_[0]->start_time ) }

sub nano_seconds_duration   { nano_seconds( $_[0]->duration ) }



sub DEMOLISH {
    my $self = shift;
    my $in_global_destruction = shift;
    
    $self->on_DEMOLISH->( $self )
        unless $in_global_destruction;
    
    return
}



1;
