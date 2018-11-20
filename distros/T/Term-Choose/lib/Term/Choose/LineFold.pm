package Term::Choose::LineFold;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.632';

use Exporter qw( import );

our @EXPORT_OK = qw( line_fold print_columns cut_to_printwidth );

BEGIN {
    if ( $ENV{TC_AMBIGUOUS_WIDE} ) {
        require Term::Choose::LineFold::CharWidthAmbiguousWide;
        Term::Choose::LineFold::CharWidthAmbiguousWide->import( 'table_char_width' );
    }
    else {
        require Term::Choose::LineFold::CharWidthDefault;
        Term::Choose::LineFold::CharWidthDefault->import( 'table_char_width' );
    }
}


my $table = table_char_width();

my $cache = [];


sub char_width {
    # $_[0] == ord $char
    my $min = 0;
    my $mid;
    my $max = $#$table;
    if ($_[0] < $table->[0][0] || $_[0] > $table->[$max][1] ) {
        return 1;
    }
    while ( $max >= $min ) {
        $mid = int( ( $min + $max) / 2 );
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
    # $_[0] == string
    my $width = 0;
    for my $i ( 0 .. ( length( $_[0] ) - 1 ) ) {
        my $c = ord substr $_[0], $i, 1;
        if ( ! defined $cache->[$c] ) {
            $cache->[$c] = char_width( $c )
        }
        $width = $width + $cache->[$c];
    }
    return $width;
}


sub cut_to_printwidth {
    # $_[0] == string
    # $_[1] == available width
    # $_[2] == return the rest (yes/no)
    my $count = 0;
    my $total = 0;
    for my $i ( 0 .. ( length( $_[0] ) - 1 ) ) {
        my $c = ord substr $_[0], $i, 1;
        if ( ! defined $cache->[$c] ) {
            $cache->[$c] = char_width( $c )
        }
        if ( ( $total = $total + $cache->[$c] ) > $_[1] ) {
            if ( ( $total - $cache->[$c] ) < $_[1] ) {
                return substr( $_[0], 0, $count ) . ' ', substr( $_[0], $count ) if $_[2];
                return substr( $_[0], 0, $count ) . ' ';
            }
            return substr( $_[0], 0, $count ), substr( $_[0], $count ) if $_[2];
            return substr( $_[0], 0, $count );

        }
        ++$count;
    }
    return $_[0], '' if $_[2];
    return $_[0];
}


sub line_fold {
    my ( $string, $avail_width, $init_tab, $subseq_tab ) = @_; #copy
    # return if ! length $string;
    for ( $init_tab, $subseq_tab ) {
        if ( $_ ) {
            s/\t/ /g;
            s/[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]+/\ \ /g;
            s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
            if ( length > $avail_width / 4 ) {
                $_ = cut_to_printwidth( $_, int( $avail_width / 2 ) );
            }
        }
        else {
            $_ = '';
        }
    }
    $string =~ s/\t/ /g;
    $string =~ s/[^\x{0a}\x{0b}\x{0c}\x{0d}\x{85}\P{Cc}]//g; # remove control chars but keep vertical spaces
    $string =~ s/[\p{Noncharacter_Code_Point}\p{Cs}]//g;
    my $regex = qr/\x{0d}\x{0a}|[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]/; # \R 5.10
    if ( $string !~ /$regex/ && print_columns( $init_tab . $string ) <= $avail_width ) {
        return $init_tab . $string;
    }
    my @paragraph;

    for my $row ( split /$regex/, $string, -1 ) { # -1 to keep trailing empty fields
        my @lines;
        $row =~ s/\s+\z//;
        my @words = split( /(?<=\S)(?=\s)/, $row );
        my $line = $init_tab;

        for my $i ( 0 .. $#words ) {
            if ( print_columns( $line . $words[$i] ) <= $avail_width ) {
                $line .= $words[$i];
            }
            else {
                my $tmp;
                if ( $i == 0 ) {
                    $tmp = $init_tab . $words[$i];
                }
                else {
                    push( @lines, $line );
                    $words[$i] =~ s/^\s+//;
                    $tmp = $subseq_tab . $words[$i];
                }
                ( $line, my $remainder ) = cut_to_printwidth( $tmp, $avail_width, 1 );
                while ( length $remainder ) {
                    push( @lines, $line );
                    $tmp = $subseq_tab . $remainder;
                    ( $line, $remainder ) = cut_to_printwidth( $tmp, $avail_width, 1 );
                }
            }
            if ( $i == $#words ) {
                push( @lines, $line );
            }
        }
        push( @paragraph, join( "\n", @lines ) );
    }
    return join( "\n", @paragraph );
}












1;
