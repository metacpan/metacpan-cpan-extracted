use v5.20;
use Object::Exercise;
use Test::More;

my $frob = Frobnicate->new;

my @testz =
(
    [ [ qw( set foo bar ) ], [ qw( bar ) ]  ],
    [ [ qw( get foo     ) ], [ qw( bar ) ]  ],

    [ [ qw( set foo     ) ], [ qw( bar ) ]  ], 
    [ [ qw( get foo     ) ], [ undef     ]  ],

);

$frob->$exercise( 'nofinish'    );
$frob->$exercise( @testz        ) for ( 1 .. 2 );
$frob->$exercise( 'finish'      );

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
