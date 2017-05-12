package Object::KeyValueCoding::Simple;

use strict;

sub implementation {
    my $__KEY_VALUE_CODING;

    $__KEY_VALUE_CODING = {
        __valueForKey => sub {
            my ( $self, $key ) = @_;
            unless ( $self->can($key) || $self->{$key} ) {
                eval {
                    return $self->valueForUndefinedKey( $key );
                };
                return undef;
            }
            if ( $self->can($key) ) {
                return $self->$key();
            }
            return $self->{$key};
        },
        __setValueForKey => sub {
            my ( $self, $value, $key ) = @_;

            my $setter = "set" . ucfirst( $key );
            if ( $self->can($setter) ) {
                return $self->$setter($value);
            }
            $setter = "set_$key";
            if ( $self->can($setter) ) {
                return $self->$setter($value);
            }
            return $self->{$key} = $value;
        },
        __valueForKeyPath => sub {
            my ( $self, $keyPath ) = @_;
            my $bits = [ split(/\./, $keyPath) ];
            my $co = $self->valueForKey( shift @$bits );
            if ( scalar @$bits > 0 ) {
                return $co->valueForKeyPath( join(".", @$bits) );
            }
            return $co;
        },
        __setValueForKeyPath => sub {
            my ( $self, $value, $keyPath ) = @_;
            my $bits = [ split (/\./, @$keyPath ) ];

            my $co = $self;

            if ( scalar @$bits > 1 ) {
                $co = $co->valueForKey( shift @$bits );
                return $co->setValueForKeyPath( $value, join( ".", @$bits ) );
            }
            return $self->setValueForKey( $value, $bits->[0] );
        },
    };
    return $__KEY_VALUE_CODING;
}

1;
