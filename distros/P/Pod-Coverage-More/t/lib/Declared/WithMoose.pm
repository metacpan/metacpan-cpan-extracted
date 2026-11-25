package Declared::WithMoose;

# Attributes of each kind, and a method that a modifier wraps.

use 5.036;
use warnings FATAL => q{all};

use Moose;

has name  => ( is => 'ro', isa => 'Str',           required  => 1,           documentation => 'Who it is' );
has items => ( is => 'rw', isa => 'ArrayRef[Int]', predicate => 'has_items', clearer       => 'clear_items' );
has peer  => ( is => 'ro', isa => 'Maybe[Declared::WithMoose]', init_arg => 'friend' );

sub greet {
    my ( $self, $who ) = @_;
    return "hi $who";
}

around greet => sub {
    my ( $orig, $self, @args ) = @_;
    return uc $self->$orig(@args);
};

__PACKAGE__->meta->make_immutable;

1;
