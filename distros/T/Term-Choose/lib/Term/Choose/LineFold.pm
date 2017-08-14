package Term::Choose::LineFold;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.507';

use Exporter qw( import );

our @EXPORT_OK = qw( line_fold print_columns cut_to_printwidth );


use Unicode::GCString;



sub print_columns {
    Unicode::GCString->new( $_[0] )->columns();
}


sub cut_to_printwidth {
    my ( $str, $avail_width, $rest ) = @_;
    my $gc_str = Unicode::GCString->new( $str );
    if ( $gc_str->columns() <= $avail_width ) {
        return $str, '' if $rest;
        return $str;
    }
    my $left = $gc_str->substr( 0, $avail_width );
    my $left_w = $left->columns();
    if ( $left_w == $avail_width ) {
        return $left->as_string, $gc_str->substr( $avail_width )->as_string if $rest;
        return $left->as_string;
    }
    if ( $avail_width < 2 ) {
        die "The terminal width is too small.";
    }
    my ( $nr_chars, $adjust );
    if ( $left_w > $avail_width ) {
        $nr_chars = int( $avail_width / 2 );
        $adjust = int( ( $nr_chars + 1 ) / 2 );
        #$nr_chars = int( $avail_width / 4 * 3 );
        #$adjust = int( ( $avail_width + 7 ) / 8 );
    }
    elsif ( $left_w < $avail_width ) {
        $nr_chars = int( $avail_width + ( $gc_str->length() - $avail_width ) / 2 );
        $adjust = int( ( $gc_str->length() - $nr_chars + 1 ) / 2 );
    }

    while ( 1 ) {
        $left = $gc_str->substr( 0, $nr_chars );
        $left_w = $left->columns();
        if ( $left_w + 1 == $avail_width ) {
            my $len_next_char = $gc_str->substr( $nr_chars, 1 )->columns();
            if ( $len_next_char == 1 ) {
                return $gc_str->substr( 0, $nr_chars + 1 )->as_string, $gc_str->substr( $nr_chars + 1 )->as_string if $rest;
                return $gc_str->substr( 0, $nr_chars + 1 )->as_string;
            }
            elsif ( $len_next_char == 2 ) {
                return $left->as_string . ' ' , $gc_str->substr( $nr_chars )->as_string if $rest;
                return $left->as_string . ' ';
            }
        }
        if ( $left_w > $avail_width ) {
            $nr_chars = int( $nr_chars - $adjust );
        }
        elsif ( $left_w < $avail_width ) {
            $nr_chars = int( $nr_chars + $adjust );
        }
        else {
            return $left->as_string, $gc_str->substr( $nr_chars )->as_string if $rest;
            return $left->as_string;
        }
        $adjust = int( ( $adjust + 1 ) / 2 );
    }
}


sub line_fold {
    my ( $string, $avail_width, $init_tab, $subseq_tab ) = @_;
    for ( $init_tab, $subseq_tab ) {
        if ( $_ ) {
            s/\s/ /g;
            s/\p{C}//g;
            if ( length > $avail_width / 4 ) {
                $_ = cut_to_printwidth( $_, int( $avail_width / 2 ) );
            }
        }
        else {
            $_ = '';
        }
    }
    $string =~ s/[^\n\P{Space}]/ /g;
    $string =~ s/[^\n\P{C}]//g;
    if ( $string !~ /\n/ && print_columns( $init_tab . $string ) <= $avail_width ) {
        return $init_tab . $string;
    }
    my $trailer = '';
    if ( $string =~ /(\n+)\z/ ) {
        $trailer = $1;
    }
    my @paragraph;

    for my $row ( split "\n", $string ) {
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
                    $tmp = $init_tab . $words[$i];;
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
    return join( "\n", @paragraph ) . $trailer;
}



1;

__END__
