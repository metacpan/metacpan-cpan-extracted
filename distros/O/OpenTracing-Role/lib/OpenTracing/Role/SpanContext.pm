package OpenTracing::Role::SpanContext;

our $VERSION = 'v0.86.0';

use Moo::Role;
use MooX::HandlesVia;
use MooX::Should;

use Data::GUID;
use Sub::Trigger::Lock;
use Types::Standard qw/HashRef Str/;

has trace_id => (
    is              => 'rw',
#   should          => Uuid, # not restraints here, do so when consuming this
    init_arg        => undef,
    default         => sub { Data::GUID->new },
    trigger         => Lock,
);

has span_id => (
    is              => 'rw',
#   should          => Uuid, # not restraints here, do so when consuming this
    init_arg        => undef,
    default         => sub { Data::GUID->new },
    trigger         => Lock,
);

has baggage_items => (
    is              => 'rwp',
    should          => HashRef[Str],
    handles_via     => 'Hash',
    handles         => {
#       get_baggage_item => 'get',
        get_baggage_items => 'all',
    },
    default         => sub{ {} },
    trigger         => Lock,
);

# XXX: trigger and $obj->get_baggage_item( 'foo' ) do not play well together
#      feels like a bug in Moo or Sub::Trigger::Lock
#
sub get_baggage_item {
    my $self = shift;
    my $item_key = shift;
    
    return { $self->get_baggage_items() }->{ $item_key }
}

sub new_clone {
    my $self = shift;
    
    my $class = ref $self;
    
    $class->new( %$self )
}

sub with_trace_id { $_[0]->clone_with( trace_id => $_[1] ) }

sub with_span_id { $_[0]->clone_with( span_id => $_[1] ) }

sub with_baggage_item {
    my ( $self, $key, $value ) = @_;
    
    $self->clone_with(
        baggage_items => { $self->get_baggage_items(), $key => $value },
    );
}

sub with_baggage_items {
    my ( $self, %args ) = @_;
    
    $self->clone_with(
        baggage_items => { $self->get_baggage_items(), %args },
    );
}

sub clone_with {
    my ( $self, @args ) = @_;
    
    bless { %$self, @args }, ref $self;
    
}



BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::SpanContext'
}

1;
