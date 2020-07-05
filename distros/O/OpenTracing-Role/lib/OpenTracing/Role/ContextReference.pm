package OpenTracing::Role::ContextReference;

our $VERSION = 'v0.82.0';

use Moo::Role;
use MooX::Enumeration;
use MooX::ProtectedAttributes;

use OpenTracing::Types qw/SpanContext/;
use Types::Standard qw/Enum/;

use constant CHILD_OF     => 'child_of';
use constant FOLLOWS_FROM => 'follows_from';

protected_has reference_type => (
    is => 'ro',
    isa => Enum[ CHILD_OF, FOLLOWS_FROM ],
);

has referenced_context => (
    is => 'ro',
    isa => SpanContext,
    required => 1,
    reader => 'get_referenced_context',
);

sub new_child_of {
    $_[0]->new(
        reference_type => CHILD_OF,
        referenced_context => $_[1],
    )
}

sub type_is_child_of { $_[0]->reference_type eq CHILD_OF }

sub new_follows_from {
    $_[0]->new(
        reference_type => FOLLOWS_FROM,
        referenced_context => $_[1],
    )
}

sub type_is_follows_from { $_[0]->reference_type eq FOLLOWS_FROM }



BEGIN {
    with 'OpenTracing::Interface::ContextReference'
        if $ENV{OPENTRACING_INTERFACE};
}



1;
