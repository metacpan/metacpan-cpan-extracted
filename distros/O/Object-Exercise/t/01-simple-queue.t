use v5.20;

use Test::More;

use Object::Exercise;

my $frob = Frobnicate->new;

my @testz =
(
    verbose =>

    [ [ qw( set foo bar ) ], [ qw( bar ) ]  ],
    [ [ qw( get foo     ) ], [ qw( bar ) ]  ],

    # same result in both cases

    [
        noverbose =>

        [ qw( set foo     ) ], [ qw( bar ) ]
    ],
    [
        'verbose=0',
        
        [ qw( get foo     ) ], [ undef     ] 
    ],

);

$frob->$exercise( @testz );

package Frobnicate;

use strict;

sub new
{
    my $proto = shift;

    bless {}, ref $proto || $proto
}

sub set
{
    my ( $obj, $key, $value ) = @_;

    @_ > 2
    ? $obj->{ $key } = $value
    : delete $obj->{ $key }
}

sub get
{
    my ( $obj, $key ) = @_;

    $obj->{ $key }
}

0
__END__
