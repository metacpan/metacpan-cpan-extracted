package Salvation::TC::Meta;

=head1 NAME

Salvation::TC::Meta - Базовый класс для классов внутри Salvation::TC

=cut

use strict;
use warnings;

=head1 METHODS

=cut

=head2 new()

=cut

sub new {

    my ( $proto, %args ) = @_;

    die( 'Metaclass must have a name' ) unless( defined $args{ 'name' } );

    return bless( \%args, ( ref( $proto ) || $proto ) );
}

=head2 name()

=cut

sub name {

    my ( $self ) = @_;

    return $self -> { 'name' };
}

1;

__END__
