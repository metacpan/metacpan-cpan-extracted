package Salvation::TC::Meta::Type::Union;

=head1 NAME

Salvation::TC::Meta::Type::Union - Класс для объединённых типов

=cut

use strict;
use warnings;
use boolean;

use base 'Salvation::TC::Meta::Type';

use Scalar::Util 'blessed';
use Salvation::TC::Exception::WrongType::TC ();

=head1 METHODS

=cut

=head2 new()

=cut

sub new {

    my ( $proto, %args ) = @_;

    die( 'Type union metaclass must have types list' ) unless( defined $args{ 'types' } );
    die( 'Types list must be an ArrayRef' ) if( ref( $args{ 'types' } ) ne 'ARRAY' );

    foreach ( @{ $args{ 'types' } } ) {

        unless( defined $_ && blessed $_ && $_ -> isa( 'Salvation::TC::Meta::Type' ) ) {

            die( 'Types list must be an ArrayRef[Salvation::TC::Meta::Type]' );
        }
    }

    $args{ 'validator' } = $proto -> build_validator( @args{ 'name', 'types' } );

    return $proto -> SUPER::new( %args );
}

=head2 types()

=cut

sub types {

    my ( $self ) = @_;

    return $self -> { 'types' };
}

=head2 build_validator( Str $name, ArrayRef[Salvation::TC::Meta::Type] $types )

=cut

sub build_validator {

    my ( $self, $name, $types ) = @_;

    return sub {

        my ( $value ) = @_;

        my @errors = ();

        foreach my $type ( @$types ) {

            my $check_passed = true;

            eval { $type -> check( $value ) };

            if( $@ ) {

                if( blessed( $@ ) && $@ -> isa( 'Salvation::TC::Exception::WrongType' ) ) {

                    push( @errors, Salvation::TC::Exception::WrongType::TC -> new(
                        type => $type -> name(), value => $value,
                        ( $@ -> isa( 'Salvation::TC::Exception::WrongType::TC' ) ? (
                            prev => $@,
                        ) : () )
                    ) );

                    $check_passed = false;

                } else {

                    die( $@ );
                }
            }

            return true if( $check_passed );
        }

        Salvation::TC::Exception::WrongType::TC -> throw(
            type => $name, value => $value, prev => \@errors,
        );
    };
}

=head2 coerce( Any $value )

=cut

sub coerce {

    my ( $self, $value ) = @_;

    foreach my $type ( @{ $self -> types() } ) {

        {
            local $SIG{ '__DIE__' } = 'DEFAULT';

            eval {
                my $new_value = $type -> coerce( $value );

                $type -> check( $new_value ); # true или die

                $value = $new_value;
            };
        }

        if( $@ ) {

            if( blessed( $@ ) && $@ -> isa( 'Salvation::TC::Exception::WrongType' ) ) {

                next;

            } else {

                die( $@ );
            }
        }

        return $value; # Moose возвращает либо старое, либо приведённое значение
    }

    return $value; # Moose возвращает либо старое, либо приведённое значение
}


1;

__END__
