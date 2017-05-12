package Salvation::TC::Meta::Type;

=head1 NAME

Salvation::TC::Meta::Type - Класс для простых типов

=cut

use strict;
use warnings;
use boolean;

use base 'Salvation::TC::Meta';

use Scalar::Util 'blessed';

=head1 METHODS

=cut

=head2 new()

=cut

sub new {

    my ( $proto, %args ) = @_;

    die( 'Type metaclass must have validator' ) unless( defined $args{ 'validator' } );
    die( 'Validator must be a CodeRef' ) if( ref( $args{ 'validator' } ) ne 'CODE' );

    $args{ 'coercion_map' } = []; # Salvation::TC::Meta::Type => CodeRef

    if( exists $args{ 'parent' } ) {

        unless(
            defined $args{ 'parent' } && blessed $args{ 'parent' }
            && $args{ 'parent' } -> isa( 'Salvation::TC::Meta::Type' )
        ) {

            die( 'Parent type must be a Salvation::TC::Meta::Type' );
        }

        my $self_validator   = $args{ 'validator' };
        my $parent_validator = $args{ 'parent' } -> validator();

        $args{ 'validator' } = sub {
            $parent_validator -> ( $_[ 0 ] ) && $self_validator -> ( $_[ 0 ] )
        };
    }

    if( exists $args{ 'base' } ) {

        unless(
            defined $args{ 'base' } && blessed $args{ 'base' }
            && $args{ 'base' } -> isa( 'Salvation::TC::Meta::Type' )
        ) {

            die( 'Base type must be a Salvation::TC::Meta::Type' );
        }
    }

    foreach my $spec (
        [ 'signed_type_generator', 'Signed type generator' ],
        [ 'length_type_generator', 'Length type generator' ],
    ) {
        my ( $key, $name ) = @$spec;

        if( exists $args{ $key } && defined $args{ $key } && ( ref( $args{ $key } ) ne 'CODE' ) ) {

            die( "${name} must be a CodeRef" );
        }
    }

    return $proto -> SUPER::new( %args );
}

=head2 validator()

=cut

sub validator {

    my ( $self ) = @_;

    return $self -> { 'validator' };
}

=head2 check( Any $value )

=cut

sub check {

    my ( $self, $value ) = @_;

    return $self -> validator() -> ( $value );
}

=head2 signature()

=cut

sub signature {

    my ( $self ) = @_;

    return $self -> { 'signature' };
}

=head2 options()

=cut

sub options {

    my ( $self ) = @_;

    return $self -> { 'options' } //= {};
}

=head2 has_signature()

=cut

sub has_signature {

    my ( $self ) = @_;

    return exists $self -> { 'signature' };
}

=head2 is_signature_strict()

=cut

sub is_signature_strict {

    my ( $self ) = @_;

    return ( $self -> has_signature() && !! ( $self -> options() -> { 'strict' } // 0 ) );
}

=head2 coercion_map()

=cut

sub coercion_map {

    my ( $self ) = @_;

    return $self -> { 'coercion_map' };
}

=head2 parent()

=cut

sub parent {

    my ( $self ) = @_;

    return $self -> { 'parent' };
}

=head2 base()

=cut

sub base {

    my ( $self ) = @_;

    return $self -> { 'base' };
}

=head2 has_base()

=cut

sub has_base {

    my ( $self ) = @_;

    return exists $self -> { 'base' };
}

=head2 has_parent()

=cut

sub has_parent {

    my ( $self ) = @_;

    return exists $self -> { 'parent' };
}

=head2 signed_type_generator()

=cut

sub signed_type_generator {

    my ( $self ) = @_;

    return $self -> { 'signed_type_generator' };
}

=head2 length_type_generator()

=cut

sub length_type_generator {

    my ( $self ) = @_;

    return $self -> { 'length_type_generator' };
}

=head2 sign( ArrayRef signature, HashRef options )

Генерирует валидатор для текущего типа на основе подписи.

=cut

sub sign {

    my ( $self, $signature, $options ) = @_;

    my $signed_type_generator = $self -> signed_type_generator();

    unless( defined $signed_type_generator ) {

        die( sprintf( 'Type %s cannot be signed', $self -> name() ) )
    }

    my $signed_validator = $signed_type_generator -> ( $signature, $options );

    return sub {

        $self -> check( $_[ 0 ] ) && $signed_validator -> ( $_[ 0 ] )
    };
}

=head2 length_checker( Int $min, Maybe[Int] $max )

Генерирует валидатор для текущего типа на основе спецификации длины.

=cut

sub length_checker {

    my ( $self, $min, $max ) = @_;

    my $length_type_generator = $self -> length_type_generator();

    unless( defined $length_type_generator ) {

        die( sprintf( 'Length of type %s could not be checked', $self -> name() ) );
    }

    my $length_validator = $length_type_generator -> ( $min, $max );

    return sub {

        $self -> check( $_[ 0 ] ) && $length_validator -> ( $_[ 0 ] )
    };
}

=head2 add_coercion( Salvation::TC::Meta::Type $from, CodeRef $how )

=cut

sub add_coercion {

    my ( $self, $from, $how ) = @_;

    push( @{ $self -> { 'coercion_map' } }, [ $from => $how ] );

    return;
}

=head2 coerce( Any $value )

=cut

sub coerce {

    my ( $self, $value ) = @_;

    foreach my $rule ( @{ $self -> coercion_map() } ) {

        {
            local $SIG{ '__DIE__' } = 'DEFAULT';

            eval { $rule -> [ 0 ] -> check( $value ) };
        }

        if( $@ ) {

            if( blessed( $@ ) && $@ -> isa( 'Salvation::TC::Exception::WrongType' ) ) {

                next;

            } else {

                die( $@ );
            }
        };

        local $_ = $value; # Ради соответствия API Moose

        $value = $rule -> [ 1 ] -> ();

        last;
    }

    return $value; # Moose возвращает либо старое, либо приведённое значение
}

1;

__END__
