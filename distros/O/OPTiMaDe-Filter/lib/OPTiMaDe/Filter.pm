package OPTiMaDe::Filter;

use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = '0.7.2'; # VERSION
our $OPTiMaDe_VERSION = '1.0.0-rc.1';

# ABSTRACT: OPTiMaDe filter language parser/composer

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
