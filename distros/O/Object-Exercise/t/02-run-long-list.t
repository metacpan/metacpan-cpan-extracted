use v5.20;

use Test::More;

use Object::Exercise    qw( plan );

SKIP:
{
    skip 'RUN_LARGE_TEST not set', 1
    unless $ENV{ RUN_LARGE_TEST };

    my @testz = ();

    my @keyz    = ( 'a' .. 'z' );

    my %valz    = ();

    for( 1 .. 16_385 )
    {
        my $key = $keyz[ rand @keyz ];

        my $val = 1 + int rand 100;

        if( int rand 2 )
        {
            $valz{ $key } = $val;

            push @testz,
            [
                [ set => $key, $val ],
                [ $val              ],
                "Set $key => $val"
            ];
        }
        else
        {
            my $show = exists $valz{ $key } ? $valz{ $key } : '';

            push @testz,
            [
                [ get => $key   ],
                [ $valz{ $key } ],
                "Get $key == $show"
            ];
        }
    }

    $exercise->( t::Frobnicate->new, @testz );
}

done_testing
unless $ENV{ RUN_LARGE_TEST };

package t::Frobnicate;

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

__END__
