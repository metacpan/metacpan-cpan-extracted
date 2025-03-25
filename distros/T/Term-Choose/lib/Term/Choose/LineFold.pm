package Term::Choose::LineFold;

use warnings;
use strict;
use 5.10.0;

our $VERSION = '1.769';

use Exporter qw( import );

our @EXPORT_OK = qw( line_fold print_columns cut_to_printwidth );

use Carp qw( croak );

use Term::Choose::Constants qw( PH SGR_ES EXTRA_W );
use Term::Choose::Screen    qw( get_term_size );


BEGIN {
    if ( exists $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE} ) {                                       #
        if ( $ENV{TC_AMBIGUOUS_WIDTH_IS_WIDE} ) {
            require Term::Choose::LineFold::CharWidthAmbiguousWide;
            Term::Choose::LineFold::CharWidthAmbiguousWide->import( 'table_char_width' );
        }
        else {
            require Term::Choose::LineFold::CharWidthDefault;
            Term::Choose::LineFold::CharWidthDefault->import( 'table_char_width' );
        }
    }                                                                                       #
    else {                                                                                  #
        if ( $ENV{TC_AMBIGUOUS_WIDE} ) {                                                    #
            require Term::Choose::LineFold::CharWidthAmbiguousWide;                         #
            Term::Choose::LineFold::CharWidthAmbiguousWide->import( 'table_char_width' );   #
        }                                                                                   #
        else {                                                                              #
            require Term::Choose::LineFold::CharWidthDefault;                               #
            Term::Choose::LineFold::CharWidthDefault->import( 'table_char_width' );         #
        }                                                                                   #
    }                                                                                       #
}


my $table = table_char_width();

my $cache = {};


sub _char_width {
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
        $width = $width + (
            defined $cache->{$c}
            ? $cache->{$c}
            : ( $cache->{$c} = _char_width( $c ) )
        );
    }
    return $width;
}


sub cut_to_printwidth {
    my ( $str, $avail_width ) = @_;
    my $return_remainder = wantarray;
    my $count = 0;
    my $total = 0;
    my $c;
    for my $i ( 0 .. ( length( $str ) - 1 ) ) {
        $c = ord substr $str, $i, 1;
        if ( ! defined $cache->{$c} ) {
            $cache->{$c} = _char_width( $c )
        }
        if ( ( $total = $total + $cache->{$c} ) > $avail_width ) {
            if ( ( $total - $cache->{$c} ) < $avail_width ) {
                return substr( $str, 0, $count ) . ' ', substr( $str, $count ) if $return_remainder;
                return substr( $str, 0, $count ) . ' ';
            }
            return substr( $str, 0, $count ), substr( $str, $count ) if $return_remainder;
            return substr( $str, 0, $count );

        }
        ++$count;
    }
    return $str, '' if $return_remainder;
    return $str;
}


sub line_fold {
    my ( $str, $opt ) = @_; # copy $str
    if ( ! length $str ) {
        return $str;
    }
    ################################### 24.03.2025
    if ( defined $opt && ! ref $opt ) {
        my $width = $opt;
        $opt = $_[2] // {};
        $opt->{width} = $width;
    }
    ###################################
    $opt //= {};
    $opt->{join} //= 1;
    if ( ! defined $opt->{width} ) {
        my ( $term_width, undef ) = get_term_size();
        $opt->{width} = $term_width + EXTRA_W;
    }
    elsif ( $opt->{width} !~ /^[1-9][0-9]*\z/ ) {
        croak "Option 'width': '$opt->{width}' is not an Integer 1 or greater!";
    }
    my $max_tab_width = int( $opt->{width} / 2 );
    for ( $opt->{init_tab}, $opt->{subseq_tab} ) {
        if ( length ) {
            if ( /^[0-9]+\z/ ) {
                $_ = ' ' x $_;
            }
            else {
                s/\t/ /g;
                s/\v+/\ \ /g; ##
                s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]//g;
            }
            if ( length > $max_tab_width ) {
                $_ = cut_to_printwidth( $_, $max_tab_width );
            }
        }
        else {
            $_ = '';
        }
    }
    my @color;
    if ( $opt->{color} ) {
        $str =~ s/${\PH}//g;
        $str =~ s/(${\SGR_ES})/push( @color, $1 ) && ${\PH}/ge;
    }
    if ( $opt->{binary_filter} && substr( $str, 0, 100 ) =~ /[\x00-\x08\x0B-\x0C\x0E-\x1F]/ ) {
        #$str = $self->{binary_filter} == 2 ? sprintf("%v02X", $_[0]) =~ tr/./ /r : 'BNRY';  # perl 5.14
        if ( $opt->{binary_filter} == 2 ) {
            ( $str = sprintf( "%v02X", $_[0] ) ) =~ tr/./ /; # use unmodified string
        }
        else {
            $str = 'BNRY';
        }
    }
    $str =~ s/\t/ /g;
    $str =~ s/[^\v\P{Cc}]//g; # remove control chars but keep vertical spaces
    $str =~ s/[\p{Noncharacter_Code_Point}\p{Cs}]//g;
    if ( $str !~ /\R/ && print_columns( $opt->{init_tab} . $str ) <= $opt->{width} && ! @color ) {
        return $opt->{init_tab} . $str;
    }
    my @paragraphs;

    for my $row ( split /\R/, $str, -1 ) { # -1 to keep trailing empty fields
        my @lines;
        $row =~ s/\s+\z//;
        my @words = split( /(?<=\S)(?=\s)/, $row );
        my $line = $opt->{init_tab};

        for my $i ( 0 .. $#words ) {
            if ( print_columns( $line . $words[$i] ) <= $opt->{width} ) {
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
                ( $line, my $remainder ) = cut_to_printwidth( $tmp, $opt->{width} );
                while ( length $remainder ) {
                    push( @lines, $line );
                    $tmp = $opt->{subseq_tab} . $remainder;
                    ( $line, $remainder ) = cut_to_printwidth( $tmp, $opt->{width} );
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
        my $last_color;
        for my $paragraph ( @paragraphs ) {
            if ( ! $opt->{join} ) {
                if ( $last_color ) {
                    $paragraph = $last_color . $paragraph;
                }
                my $count = () = $paragraph =~ /${\PH}/g;
                if ( $count ) {
                    $last_color = $color[$count - 1];
                }
            }
            $paragraph =~ s/${\PH}/shift @color/ge;
            if ( ! @color ) {
                last;
            }
        }
        $paragraphs[-1] .= "\e[0m";
    }
    if ( $opt->{join} ) {
        return join( "\n", @paragraphs );
    }
    else {
        return @paragraphs;
    }
}



1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Term::Choose::LineFold

=head1 VERSION

Version 1.769

=cut

=head1 DESCRIPTION

I<Width> in this context refers to the number of occupied columns of a character string on a terminal with a monospaced
font.

By default ambiguous width characters are treated as half width. If the environment variable
C<TC_AMBIGUOUS_WIDTH_IS_WIDE> is set to a true value, ambiguous width characters are treated as full width.

=head1 EXPORT

Nothing by default.

    use Term::Choose qw( print_columns );

=head1 FUNCTIONS

=head2 print_columns

Get the number of occupied columns of a character string on a terminal.

The string passed to this function is a decoded string, free of control characters, non-characters, and surrogates.

    $print_width = print_columns( $string );

=head2 cut_to_printwidth

Cut a string to a specified width.

The string passed to this function is a decoded string, free of control characters, non-characters, and surrogates.

    $cut_string = cut_to_printwidth( $string, $width );

When used in a list context, the function returns both the cut string and the remaining portion of the original string.
If there is no remaining portion, it returns an empty string instead.

    ( $cut_string, $remainder ) = cut_to_printwidth( $string, $width );

If the width of the cut string is less than C<$width>, a space character is appended.

=head2 line_fold

Fold a string.

This function accepts a decoded string. Control characters (excluding vertical spaces), non-characters, and surrogates
are removed before the string is folded. Changes are applied to a copy; the passed string is unchanged.

    $folded_string = line_fold( $string );

    $folded_string = line_fold( $string, { width => 120, color => 1 } );

=head3 Options

=over

=item width

If not set, defaults to the terminal width.

I<width> is C<1> or greater.

=item init_tab

Sets the initial tab inserted at the beginning of paragraphs. If a positive integer is provided, the initial tab will be
I<int_tab> spaces. If a non-numeric value is provided, it will be used as the initial tab directly. By default, no
initial tab is inserted. If the initial tab is longer than half the available width, it will be cut to half the
available width

=item subseq_tab

Sets the subsequent tab inserted at the beginning of all broken lines (excluding paragraph beginnings). If a positive
integer is provided, the subsequent tab will be I<subseq_tab> spaces. If a non-numeric value is provided, it will be
used as the subsequent tab directly. By default, no subsequent tab is inserted. If the subsequent tab is longer than
half the available width, it will be cut to half the available width

=item color

Enables support for ANSI SGR escape sequences. If enabled, all zero-width no-break spaces (C<0xfeff>) are removed.

I<color> is C<0> or C<1>.

=back

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
