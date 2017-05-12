use strict;
use warnings;

use Test::More 'tests' => 1;

# Borg is a foreign hash-based class that overloads bool
package Borg;
{
    use overload 'bool' => \&bool;

    sub new {
        my $class = shift;
        my %self  = @_;
        return ( bless( \%self, $class ) );
    }

    sub get_borg {
        my ( $self, $data ) = @_;
        return ( $self->{$data} );
    }

    sub set_borg {
        my ( $self, $key, $value ) = @_;
        $self->{$key} = $value;
    }

    sub warn {
        return ('Resistance is futile');
    }
    sub bool { my $self = shift; return scalar keys %$self; }
}

package Foo;
{
    use Object::InsideOut qw(Borg);

    my @objs : Field('Acc'=>'obj', 'Type' => 'list');

    my %init_args : InitArgs = (
        'OBJ' => {
            'RE'    => qr/^obj$/i,
            'Field' => \@objs,
            'Type'  => 'list',
        },
        'BORG' => { 'RE' => qr/^borg$/i, }
    );

    sub init : Init {
        my ( $self, $args ) = @_;

        $self->inherit( Borg->new() );

        if ( exists( $args->{'BORG'} ) ) {
            $self->set_borg( 'borg' => $args->{'BORG'} );
        }
    }
}

package main;
MAIN:
{
    eval { my $obj = Foo->new(); };
    ok( $@ eq '', 'Created object with overloaded bool operation' );
}

exit(0);

# EOF
