package Term::Choose::LineFold::PP;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';

use Exporter qw( import );

our @EXPORT_OK = qw( char_width print_columns cut_to_printwidth adjust_to_printwidth );

BEGIN {
    if ( exists $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE} ) {                                          # 24.03.2025
        if ( $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE} ) {
            require Term::Choose::LineFold::PP::CharWidthAmbiguousWide;
            Term::Choose::LineFold::PP::CharWidthAmbiguousWide->import( 'table_char_width' );
        }
        else {
            require Term::Choose::LineFold::PP::CharWidthDefault;
            Term::Choose::LineFold::PP::CharWidthDefault->import( 'table_char_width' );
        }
    }                                                                                         #
    else {                                                                                    #
        if ( $ENV{TC_AMBIGUOUS_WIDE} ) {                                                      #
            require Term::Choose::LineFold::PP::CharWidthAmbiguousWide;                       #
            Term::Choose::LineFold::PP::CharWidthAmbiguousWide->import( 'table_char_width' ); #
        }                                                                                     #
        else {                                                                                #
            require Term::Choose::LineFold::PP::CharWidthDefault;                             #
            Term::Choose::LineFold::PP::CharWidthDefault->import( 'table_char_width' );       #
        }                                                                                     #
    }                                                                                         #
}


my $table = table_char_width();

my $cache = {};


sub char_width {
    #my $c = $_[0];
    my $min = 0;
    my $mid;
    my $max = $#$table;
    if ( $_[0] < $table->[0][0] || $_[0] > $table->[$max][1] ) {
        return 1;
    }
    while ( $max >= $min ) {
        $mid = int( ( $min + $max ) / 2 );
        if ( $_[0] > $table->[$mid][1] ) {
            $min = $mid + 1;
        }
        elsif ( $_[0] < $table->[$mid][0] ) {
            $max = $mid - 1;
        }
        else {
            return $table->[$mid][2];
        }
    }
    return 1;
}

sub print_columns {
    #my $str = $_[0];
    my $width = 0;
    my $c;
    for my $i ( 0 .. ( length( $_[0] ) - 1 ) ) {
        $c = ord substr $_[0], $i, 1;
        $width += ( $cache->{$c} //= char_width( $c ) );
    }
    return $width;
}


sub cut_to_printwidth {
    #my ( $str, $avail_width ) = @_;
    my $str_w = 0;
    my $c;
    for my $i ( 0 .. ( length( $_[0] ) - 1 ) ) {
        $c = ord substr $_[0], $i, 1;
        if ( ( $str_w += ( $cache->{$c} //= char_width( $c ) ) ) > $_[1] ) {
            if ( ( $str_w - $cache->{$c} ) < $_[1] ) {
                return substr( $_[0], 0, $i ) . ' ', substr( $_[0], $i ) if wantarray;
                return substr( $_[0], 0, $i ) . ' ';
            }
            return substr( $_[0], 0, $i ), substr( $_[0], $i ) if wantarray;
            return substr( $_[0], 0, $i );
        }
    }
    return $_[0], '' if wantarray;
    return $_[0];
}


sub adjust_to_printwidth {
#    my ( $str, $width ) = @_;
    my $str_w = 0;
    my $c;
    for my $i ( 0 .. ( length( $_[0] ) - 1 ) ) {
        $c = ord substr $_[0], $i, 1;
        if ( ( $str_w += ( $cache->{$c} //= char_width( $c ) ) ) > $_[1] ) {
            if ( ( $str_w - $cache->{$c} ) < $_[1] ) {
                return substr( $_[0], 0, $i ) . ' ';
            }
            return substr( $_[0], 0, $i );
        }
    }
    return $_[0] if $str_w == $_[1];
    return $_[0] . ' ' x ( $_[1] - $str_w );
}



1;

__END__
