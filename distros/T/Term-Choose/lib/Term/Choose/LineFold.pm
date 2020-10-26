package Term::Choose::LineFold;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.712';

use Exporter qw( import );

our @EXPORT_OK = qw( line_fold print_columns cut_to_printwidth );

use Term::Choose::Screen qw( normal );


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
    my $c = $_[0];
    my $min = 0;
    my $mid;
    my $max = $#$table;
    if ($c < $table->[0][0] || $c > $table->[$max][1] ) {
        return 1;
    }
    while ( $max >= $min ) {
        $mid = int( ( $min + $max ) / 2 );
        if ( $c > $table->[$mid][1] ) {
            $min = $mid + 1;
        }
        elsif ( $c < $table->[$mid][0] ) {
            $max = $mid - 1;
        }
        else {
            return $table->[$mid][2];
        }
    }
    return 1;
}


sub print_columns {
    my $str = $_[0];
    my $width = 0;
    for my $i ( 0 .. ( length( $str ) - 1 ) ) {
        my $c = ord substr $str, $i, 1;
        if ( ! defined $cache->[$c] ) {
            $cache->[$c] = char_width( $c );
        }
        $width = $width + $cache->[$c];
    }
    return $width;
}


sub cut_to_printwidth {
    my ( $str, $avail_w, $return_rest ) = @_;
    my $count = 0;
    my $total = 0;
    for my $i ( 0 .. ( length( $str ) - 1 ) ) {
        my $c = ord substr $str, $i, 1;
        if ( ! defined $cache->[$c] ) {
            $cache->[$c] = char_width( $c )
        }
        if ( ( $total = $total + $cache->[$c] ) > $avail_w ) {
            if ( ( $total - $cache->[$c] ) < $avail_w ) {
                return substr( $str, 0, $count ) . ' ', substr( $str, $count ) if $return_rest;
                return substr( $str, 0, $count ) . ' ';
            }
            return substr( $str, 0, $count ), substr( $str, $count ) if $return_rest;
            return substr( $str, 0, $count );

        }
        ++$count;
    }
    return $str, '' if $return_rest;
    return $str;
}


sub line_fold {
    my ( $str, $avail_w, $opt ) = @_; #copy $str
    return $str if ! defined $str || ! length $str;
    for ( $opt->{init_tab}, $opt->{subseq_tab} ) {
        if ( defined $_ && length $_ ) {
            s/\t/ /g;
            s/[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]+/\ \ /g;
            s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
            if ( length > $avail_w / 4 ) {
                $_ = cut_to_printwidth( $_, int( $avail_w / 2 ) );
            }
        }
        else {
            $_ = '';
        }
    }
    my @color;
    if ( $opt->{color} ) {
        $str =~ s/\x{feff}//g;
        $str =~ s/(\e\[[\d;]*m)/push( @color, $1 ) && "\x{feff}"/ge;
    }
    $str =~ s/\t/ /g;
    $str =~ s/[^\x{0a}\x{0b}\x{0c}\x{0d}\x{85}\P{Cc}]//g; # remove control chars but keep vertical spaces
    $str =~ s/[\p{Noncharacter_Code_Point}\p{Cs}]//g;
    my $regex = qr/\x{0d}\x{0a}|[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]/; # \R 5.10
    if ( $str !~ /$regex/ && print_columns( $opt->{init_tab} . $str ) <= $avail_w && ! @color ) {
        return $opt->{init_tab} . $str;
    }
    my @paragraphs;

    for my $row ( split /$regex/, $str, -1 ) { # -1 to keep trailing empty fields
        my @lines;
        $row =~ s/\s+\z//;
        my @words = split( /(?<=\S)(?=\s)/, $row );
        my $line = $opt->{init_tab};

        for my $i ( 0 .. $#words ) {
            if ( print_columns( $line . $words[$i] ) <= $avail_w ) {
                $line .= $words[$i];
            }
            else {
                my $tmp;
                if ( $i == 0 ) {
                    $tmp = $opt->{init_tab} . $words[$i];
                }
                else {
                    push( @lines, $line );
                    $words[$i] =~ s/^\s+//;
                    $tmp = $opt->{subseq_tab} . $words[$i];
                }
                ( $line, my $remainder ) = cut_to_printwidth( $tmp, $avail_w, 1 );
                while ( length $remainder ) {
                    push( @lines, $line );
                    $tmp = $opt->{subseq_tab} . $remainder;
                    ( $line, $remainder ) = cut_to_printwidth( $tmp, $avail_w, 1 );
                }
            }
            if ( $i == $#words ) {
                push( @lines, $line );
            }
        }
        if ( $opt->{join} ) {
            push( @paragraphs, join( "\n", @lines ) );
        }
        else {
            if ( @lines ) {
                push( @paragraphs, @lines );
            }
            else {
                push( @paragraphs, '' );
            }
        }
    }
    if ( @color ) {
        for my $paragraph ( @paragraphs ) {
            $paragraph =~ s/\x{feff}/shift @color/ge;
            if ( ! @color ) {
                last;
            }
        }
        $paragraphs[-1] .= normal();
    }
    if ( $opt->{join} ) {
        return join( "\n", @paragraphs );
    }
    else {
        return @paragraphs;
    }
}










1;
