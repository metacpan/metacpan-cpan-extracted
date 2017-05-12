package Salvation::TC::Type::HashRef;

use strict;
use warnings;

use base 'Salvation::TC::Type::Ref';

use Scalar::Util 'blessed';
use Salvation::TC::Exception::WrongType ();
use Salvation::TC::Exception::WrongType::TC ();


sub Check {

    my ( $class, $value ) = @_;

    ( ref( $value ) eq 'HASH' ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'HashRef', 'value' => $value );
}

sub create_validator_from_sig {

    my ( $class, $signature, $options ) = @_;

    my %checks = ();

    foreach my $el ( @$signature ) {

        my ( $param, $type ) = @$el{ 'param', 'type' };

        die( 'Only named parameters are supported' ) if( $param -> { 'positional' } );

        my $wrap = sub {

            my ( $code ) = @_;

            return sub {

                my ( @input ) = @_;

                eval { $code -> ( @input ) };

                if( $@ ) {

                    if( blessed( $@ ) && $@ -> isa( 'Salvation::TC::Exception::WrongType' ) ) {

                        Salvation::TC::Exception::WrongType::TC -> throw(
                            type => $@ -> getType(),
                            value => $@ -> getValue(),
                            param_name => $param -> { 'name' },
                            ( $@ -> isa( 'Salvation::TC::Exception::WrongType::TC' ) ? (
                                prev => $@ -> getPrev(),
                            ) : () ),
                        );

                    } else {

                        die( $@ );
                    }
                };
            };
        };

        if( exists $checks{ $param -> { 'name' } } ) {

            die( 'Invalid signature: parameter ' . $param -> { 'name' } . ' is specified twice' );
        }

        if( $param -> { 'optional' } ) {

            $checks{ $param -> { 'name' } } = $wrap -> ( sub {

                if( exists $_[ 0 ] -> { $param -> { 'name' } } ) {

                    $type -> check( $_[ 0 ] -> { $param -> { 'name' } } )
                }

            } );

        } else {

            $checks{ $param -> { 'name' } } = $wrap -> ( sub {

                exists $_[ 0 ] -> { $param -> { 'name' } } || Salvation::TC::Exception::WrongType
                    -> throw( 'type' => $type -> name(), 'value' => '(not exists)' );

                $type -> check( $_[ 0 ] -> { $param -> { 'name' } } );

            } );
        }
    }

    my @checks = values( %checks );

    return sub {

        $_ -> ( $_[ 0 ] ) for @checks;

        if( $options -> { 'strict' } ) {

            eval {
                while( my ( $key ) = each( %{ $_[ 0 ] } ) ) {

                    unless( exists $checks{ $key } ) {

                        Salvation::TC::Exception::WrongType -> throw(
                            'type' => "HashRef.${key}",
                            'value' => '(key is not expected)'
                        );
                    }
                }
            };

            if( $@ ) {

                keys( %{ $_[ 0 ] } ); # reset iterator
                die( $@ );
            }
        }

        1;
    };
}

sub create_length_validator {

    my ( $class, $min, $max ) = @_;

    return sub {

        my $len = scalar( keys( %{ $_[ 0 ] } ) );

        if( ( $len < $min ) || ( defined $max && ( $len > $max ) ) ) {

            Salvation::TC::Exception::WrongType -> throw(
                'type' => sprintf( 'HashRef{%s,%s}', $min, ( $max // '' ) ),
                'value' => $_[ 0 ]
            );
        }

        1;
    };
}

1;

__END__
