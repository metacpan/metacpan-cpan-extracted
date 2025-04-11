#!/usr/bin/env perl
use warnings;
use 5.014;
use utf8;
use open qw(:std :utf8);
use Data::Dumper;
use LWP::Protocol::https;
use WWW::Mechanize::Cached;
use Term::Choose;
# https://www.unicode.org/Public/UNIDATA/UnicodeData.txt
# https://unicode.org/reports/tr44/#UnicodeData.txt
# https://www.unicode.org/Public/UNIDATA/EastAsianWidth.txt
# https://www.unicode.org/reports/tr11/
# https://www.unicode.org/Public/UNIDATA/extracted/DerivedGeneralCategory.txt'

$SIG{__WARN__} = sub { die @_ };


sub unicode_data {
    my $mech = WWW::Mechanize::Cached->new();
    my $res = $mech->get( 'https://www.unicode.org/Public/UNIDATA/UnicodeData.txt' );
    if ( ! $res->is_success ) {
        die $res->status_line;
    }
    my $page = $mech->content( format => 'text' );
    my $data = [ # https://unicode.org/reports/tr44/#UnicodeData.txt  1-3
        #[ qw|Hex Name General_Category Canonical_Combining_Class Bidi_Class| ]
    ];
    my $first;
    for my $row ( split /\n/, $page ) {
        my ( $codepoint, $name, $category, $combining_class, $bidi_class ) = ( split /;/, $row, -1 )[0..4];
        $codepoint = hex $codepoint;
        if ( $name =~ /First>\z/ ) {
            $first = $codepoint;
        }
        elsif ( $first ) {
            if ( $name =~ /Last>\z/ ) {
                my $last = $codepoint;
                for my $c ( $first .. $last ) {
                    $data->[$c]{category} = $category;
                    $data->[$c]{bidi_class} = $bidi_class;
                }
                $first = undef;
                $last  = undef;
            }
            else {
                die "$codepoint - $name - $category - $combining_class - $bidi_class";
            }
        }
        else {
            $data->[$codepoint]{category} = $category;
            $data->[$codepoint]{bidi_class} = $bidi_class;
        }
    }
    return $data;
}


sub east_asian_width_table {
    my $mech = WWW::Mechanize::Cached->new();
    my $res = $mech->get( 'https://www.unicode.org/Public/UNIDATA/EastAsianWidth.txt' );
    if ( ! $res->is_success ) {
        die $res->status_line;
    }
    my $page = $mech->content( format => 'text' );
    my $east_asian_width_table = [];
    for my $row ( split /\n/, $page ) {
        if ( $row =~ /^(\S+)\s*;\s*(\S\S?)\s/ ) {
            my @range = split /\.\./, $1;
            if ( @range == 1 ) {
                push @range, $1;
            }
            push @$east_asian_width_table, [ @range, $2 ];
        }
    }
    return $east_asian_width_table;
}


sub width_east_asian {
    my ( $east_asian_width_table, $c ) = @_;
    for my $e ( @$east_asian_width_table ) {
        my $begin = hex( $e->[0] );
        my $end   = hex( $e->[1] );
        if ( $c >= $begin && $c <= $end ) {
            return $e->[2];
        }
    }
    return 'N';
}


my $unicode_data = unicode_data();
my $east_asian_width_table = east_asian_width_table();
my $width_normal = [];
my $width_ambiguous = [];

for my $c ( 0x0 .. 0x10ffff ) {
    printf "0x%x\n", $c;
    my $category = $unicode_data->[$c]{category} // '';
    my $bidi_class = $unicode_data->[$c]{bidi_class} // '';
    my $east_asian_width = width_east_asian( $east_asian_width_table, $c );
    my $print_width;
    if ( $category =~ /^(?:Cc|Cs)\z/ ) {
        # Other, control
        # Other, surrogate
        $print_width = [ -1, -1 ];
    }
    elsif ( $c == 0x00AD ) {
        # Soft Hyphen (in Cf)
        # http://unicode.org/reports/tr14/#SoftHyphen  but terminals use 1 resp 2 print-width
        # Ambiguous
        $print_width = [ 1, 2 ];
    }
    elsif ( $category =~ /^(?:Mn|Me)\z/ ) {
        # Mn = Mark, nonspacing
        # Me = Mark, enclosing
        # categories might not be up to date
        $print_width = [ 0, 0 ];
    }
    elsif ( $category eq 'Cf' && $bidi_class ne 'AN' ) {
        # Cf = Other, format
        # AN = bidi clas arbic number
        # https://www.unicode.org/versions/Unicode14.0.0/ch09.pdf # 9.2 Arabic -> Signs Spanning Numbers -> Unlike ...
        $print_width = [ 0, 0 ];
    }
    elsif ( $c >= 0x1160 && $c <= 0x11FF || $c >= 0x0D7B0 && $c <= 0x0D7FF ) {
#        # https://devblogs.microsoft.com/oldnewthing/20201009-00/?p=104351
        $print_width = [ 0, 0 ];
    }
    elsif ( $east_asian_width =~ /^(?:W|F)\z/ ) {
        # W = Wide, F = Fullwidth
        # https://www.unicode.org/reports/tr11/
        $print_width = [ 2, 2 ];
    }
    elsif ( $east_asian_width eq 'A' ) {
        # A = Ambiguous,
        $print_width = [ 1, 2 ];
    }
    else {
        $print_width = [ 1, 1 ];
    }
    $width_normal->[$c] = $print_width->[0];
    $width_ambiguous->[$c] = $print_width->[1];
}


sub build_ranges {
    my ( $width_table ) = @_;
    my $ranges = [];
    my $prev = { begin => 0, end => 0, width => 9 };

    for my $c ( 0x0 .. 0x10ffff ) {
        printf "0x%x\n", $c;
        my $width = $width_table->[$c];
        my $range = [];
        if ( $prev->{width} == $width ) {
            $range = [ $prev->{begin}, $c ];
        }
        else {
            $range = [ $c, $c ];
        }
        if ( $range->[0] != $prev->{begin} ) {
            push @$ranges, $prev;
        }
        $prev = { begin => $range->[0], end => $range->[1], width => $width };
    }
    push @$ranges, $prev; # push the last $prev
    return $ranges;
}


for my $file_name ( "CharWidthAmbiguousWide.pm", "CharWidthDefault.pm" ) {
    my $ranges;
    my $amb;
    if ( $file_name eq "CharWidthDefault.pm" ) {
        $amb = 'narrow';
        $ranges = build_ranges( $width_normal );
    }
    else {
        $amb = 'wide';
        $ranges = build_ranges( $width_ambiguous );
    }
    open my $fh, '>', $file_name or die $!;
    my $module = $file_name =~ s/\.pm\z//r;

print $fh
qq|package Term::Choose::LineFold::$module;

use warnings;
use strict;
use 5.10.1;

our \$VERSION = '$Term::Choose::VERSION';

use Exporter qw( import );

our \@EXPORT_OK = qw( table_char_width );


# test with gnome-terminal - ambiguous characters set to $amb

# Control characters, non-characters and surrogates are removed before using this table.


sub table_char_width { [
|;

    my $number_of_ranges = 0;
    for my $r ( @$ranges ) {
        my $cm = '#';
        # less than 0 is Cc and Cs
        if ( $r->{width} >= 0 ) {
            $cm = '';
            $number_of_ranges++;
        }
        printf $fh "${cm}[%8s, %8s, %d],\n", sprintf( "0x%x", $r->{begin} ), sprintf( "0x%x", $r->{end} ), $r->{width};
    }

    print $fh "]\n}\n\n\n1;\n";
    close $fh;
}



