package Salvation::TC::Meta::Type::Maybe;

=head1 NAME

Salvation::TC::Meta::Type::Maybe - Класс для Maybe[`] типов.

=cut

use strict;
use warnings;

use base 'Salvation::TC::Meta::Type';

=head1 METHODS

=cut

=head2 new()

=cut

sub new {

    my ( $proto, %args ) = @_;

    my $self = $proto -> SUPER::new( %args );

    $self -> { 'validator' } = $self -> build_validator( $self -> validator() );

    return $self;
}

=head2 build_validator( CodeRef $old_validator )

=cut

sub build_validator {

    my ( $self, $old_validator ) = @_;

    return sub {

        ! defined( $_[ 0 ] ) || $old_validator -> ( @_ );
    };
}

1;

__END__
