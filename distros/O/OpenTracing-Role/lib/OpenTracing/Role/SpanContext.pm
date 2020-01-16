package OpenTracing::Role::SpanContext;

=head1 NAME

OpenTracing::Role::SpanContext - Role for OpenTracing implementations.

=head1 SYNOPSIS

    package OpenTracing::Implementation::MyBackendService::SpanContext
    
    use Moo;
    
    ...
    
    with 'OpenTracing::Role::SpanContext'
    
    1;

=cut

use Moo::Role;

use MooX::HandlesVia;

use Sub::Trigger::Lock;
use Types::Standard qw/HashRef Str/;



=head1 DESCRIPTION

This is a role for OpenTracing implenetations that are compliant with the
L<OpenTracing::Interface>.

It has been suggested that an object that implements the OpenTracing SpanContext
interface SHOULD be immutable, to avoid lifetime issues. Therefore, the
attributes are read/write-protected. Any changes tried to make, will trigger a
L<Sub::Trigger::Lock> exception.

The only way to 'mutate' the bagage items, is by using L<with_baggage_item> or
L<with_baggage_items>.

Most likely, the L<new> constructor would only be called during the extraction
phase. Depending on the framework the OpenTracing implementation is being used
for, it will be initialised with request depenent information. From there on,
additional bagage-items can be added.

Implementors should be aware of the immutable desired behavbior and should use
methods like C<with_...> to clone this object with new values, rather than just
updating any values of the the attributes.

=cut



# baggage_items
#
has baggage_items => (
    is              => 'rwp',
    isa             => HashRef[Str],
    handles_via     => 'Hash',
    handles         => {
        get_baggage_item => 'get',
        get_baggage_items => 'all',
    },
    default         => sub{ {} },
    trigger         => Lock,
);


# with_baggage_item
#
# creates a clone of the current object, with new kew/value pair added
#
sub with_baggage_item {
    my ( $self, $key, $value ) = @_;
    
    $self->_clone(
        baggage_items => { $self->get_baggage_items(), $key => $value },
    );
}


# with_baggage_items
#
# creates a clone of the current object, with list of kew/value pairs added
#
sub with_baggage_items {
    my ( $self, %args ) = @_;
    
    $self->_clone(
        baggage_items => { $self->get_bagage_items(), %args },
    );
}


# _clone
#
# Creates a shallow clone of the object, which is fine
#
sub _clone {
    my ( $self, @args ) = @_;
    ref( $self )->new( %$self, @args );
}


BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::SpanContext'
        if $ENV{OPENTRACING_INTERFACE};
}



=head1 ATTRIBUTES



=head2 baggage_items



=head1 METHODS



=head2 get_baggage_item

Returns a single value for a given key.

=head2 get_baggage_items

Returns a hash that contains all key/value pairs for the current baggage items.
By returning a hash and not a reference, it purposefully makes it hard to mutate
any of the key/value pairs in the baggage_items.

=head2 with_baggage_item

Creates a clone of the current object, with new kew/value pair added.

=head2 with_baggage_items

Creates a clone of the current object, with list of kew/value pairs added.



=head1 SEE ALSO

=over

=item L<OpenTracing::Role>

=item L<OpenTracing::Implementation>

=item L<OpenTracing::Interface::SpanContext>

=back

=cut


1;
