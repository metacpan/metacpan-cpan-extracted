package OPTiMaDe::Filter;

use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = '0.6.1';
our $OPTiMaDe_VERSION = '0.10.0-dev';

sub modify
{
    my $node = shift;
    my $code = shift;

    if( blessed $node && $node->can( 'modify' ) ) {
        return $node->modify( $code, @_ );
    } elsif( ref $node eq 'ARRAY' ) {
        return [ map { modify( $_, $code, @_ ) } @$node ];
    } else {
        return $code->( $node, @_ );
    }
}

1;
