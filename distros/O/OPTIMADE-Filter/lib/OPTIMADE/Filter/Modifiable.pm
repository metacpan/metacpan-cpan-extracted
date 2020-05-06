package OPTIMADE::Filter::Modifiable;

use strict;
use warnings;

use Scalar::Util qw(blessed);

sub modify
{
    my $node = shift;
    my $code = shift;

    if( blessed $node &&
        $node->isa( OPTIMADE::Filter::Modifiable:: ) ) {
        return $node->modify( $code, @_ );
    } elsif( ref $node eq 'ARRAY' ) {
        return [ map { modify( $_, $code, @_ ) } @$node ];
    } else {
        return $code->( $node, @_ );
    }
}

1;
