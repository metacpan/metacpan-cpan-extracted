use v5.20;

use Test::More;

use Object::Exercise;

my @testz = ();

my @keyz    = ( 'a' .. 'z' );

my %valz    = ();

for( 1 .. 10 )
{
    my $key = $keyz[ rand @keyz ];

    my $val = 1 + int rand 100;

    push @testz,
    (
        "Currently processing: '$key', '$val'",
        [
            [ set => $key, $val ],
            [ $val              ],
            "Set $key => $val"
        ],
        [
            [ get => $key       ],
            [ $val              ],
        ],
    )
}

$exercise->( t::Frobnicate->new, @testz );

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
