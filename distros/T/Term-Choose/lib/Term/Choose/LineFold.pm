package Term::Choose::LineFold;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.513';

use Exporter qw( import );

our @EXPORT_OK = qw( line_fold print_columns cut_to_printwidth );


use Unicode::GCString;



sub print_columns {
    Unicode::GCString->new( $_[0] )->columns();
}


sub cut_to_printwidth {
    # $_[0] == string,
    # $_[1] == available width
    # $_[2] == return the rest (yes/no)
    my $gc_str = Unicode::GCString->new( $_[0] );
    if ( $gc_str->columns() <= $_[1] ) {
        return $_[0], '' if $_[2];
        return $_[0];
    }
    my $left = $gc_str->substr( 0, $_[1] );
    my $left_w = $left->columns();
    if ( $left_w == $_[1] ) {
        return $left->as_string, $gc_str->substr( $_[1] )->as_string if $_[2];
        return $left->as_string;
    }
    if ( $_[1] < 2 ) {
        die "The terminal width is too small.";
    }
    my ( $nr_chars, $adjust );
    if ( $left_w > $_[1] ) {
        $nr_chars = int( $_[1] / 2 );
        $adjust = int( ( $nr_chars + 1 ) / 2 );
        #$nr_chars = int( $_[1] / 4 * 3 );
        #$adjust = int( ( $_[1] + 7 ) / 8 );
    }
    elsif ( $left_w < $_[1] ) {
        $nr_chars = int( $_[1] + ( $gc_str->length() - $_[1] ) / 2 );
        $adjust = int( ( $gc_str->length() - $nr_chars + 1 ) / 2 );
    }

    while ( 1 ) {
        $left = $gc_str->substr( 0, $nr_chars );
        $left_w = $left->columns();
        if ( $left_w + 1 == $_[1] ) {
            my $len_next_char = $gc_str->substr( $nr_chars, 1 )->columns();
            if ( $len_next_char == 1 ) {
                return $gc_str->substr( 0, $nr_chars + 1 )->as_string, $gc_str->substr( $nr_chars + 1 )->as_string if $_[2];
                return $gc_str->substr( 0, $nr_chars + 1 )->as_string;
            }
            elsif ( $len_next_char == 2 ) {
                return $left->as_string . ' ' , $gc_str->substr( $nr_chars )->as_string if $_[2];
                return $left->as_string . ' ';
            }
        }
        if ( $left_w > $_[1] ) {
            $nr_chars = int( $nr_chars - $adjust );
        }
        elsif ( $left_w < $_[1] ) {
            $nr_chars = int( $nr_chars + $adjust );
        }
        else {
            return $left->as_string, $gc_str->substr( $nr_chars )->as_string if $_[2];
            return $left->as_string;
        }
        $adjust = int( ( $adjust + 1 ) / 2 );
    }
}


sub line_fold {
    my ( $string, $avail_width, $init_tab, $subseq_tab ) = @_; #copy
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
    my @paragraph;

    for my $row ( split "\n", $string, -1 ) { # -1 to keep trailing empty fields
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
    return join( "\n", @paragraph );
}



1;

__END__
