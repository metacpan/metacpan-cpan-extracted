#!/usr/bin/env perl
use warnings;
use 5.014;
use utf8;
use open qw(:std :utf8);
use Data::Dumper;
use LWP::Protocol::https;
use WWW::Mechanize::Cached;
use Term::Choose;
use Term::Choose::Util qw( settings_menu );
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
        if ( $row =~ /^(\S+);(\S\S?)\s/ ) {
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

# Gnome-Terminal -> guake, tilda, terminator, lxterminal, tilix, sakura, xfce4-terminal (alacritty)
# KDE Konsole -> yakuake, kitty

my %info = (
    "Arabic Number Format Characters" => [
        'Win32 Console  1',
        'KDE Konsole    0',
        'Gnome-Terminal 0',
    ],
    "Hangul Jamo 0x1160..0x11ff" => [
        'KDE Konsole    1',
        'Win32 Console  1',
        'Gnome-Terminal 0',
    ],
    "Regional Indicator Symbol Letters A-Z" => [
        'Gnome-Terminal 1',
        'Win32 Console  1',
        'KDE Konsole    2',
    ],
);
my @info;
for my $key ( sort keys %info ) {
    push @info, "\e[4m$key:\e[0m";
    for my $e ( @{$info{$key}} ) {
        push @info, ( ' ' x 4 ) . $e;
    }
}
my $config = {                                  # Defaults: take the bigger value because too much space does less harm than to little space
    'arabic_number_format_characters'   => 1,   # 0, [1]
    'hangul_jamo_1160_11ff'             => 1,   # 0, [1]
    'regional_indicator_symbol_letters' => 1,   # 1, [2]
};
my $menu = [
    [ 'arabic_number_format_characters',   "- Arabic Number Format Characters",       [ 0, 1 ] ],
    [ 'hangul_jamo_1160_11ff',             "- Hangul Jamo 0x1160..0x11ff",            [ 0, 1 ] ],
    [ 'regional_indicator_symbol_letters', "- Regional Indicator Symbol Letters A-Z", [ 1, 2 ] ],
];
if ( @ARGV ) {
    my $return = settings_menu( 
        $menu, $config,
        { info => join( "\n", @info ), prompt => "\nUsed width:", clear_screen => 1, back => 'Exit', confirm => 'Confirm', color => 1 }
    );
    exit if ! defined $return;
}
my $cust_width;
for my $key ( keys %$config ) {
    for my $e ( @$menu ) {
        if ( $e->[0] eq $key ) {
            $cust_width->{$key} = $e->[2][$config->{$key}];
        }
    }
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
    if ( chr( $c ) =~ /\p{Cc}/ ) {
        # Other, control
        $print_width = [ -1, -1 ];
    }
    elsif ( $c == 0x00AD ) {
        # Soft Hyphen (in Cf)
        # http://unicode.org/reports/tr14/#SoftHyphen  terminals use 1 resp 2 print-width
        # Ambiguous
        $print_width = [ 1, 2 ];
    }
    elsif ( $category =~ /^(?:Mn|Me)\z/ ) {
        # Mn = Mark, nonspacing
        # Me = Mark, enclosing
        # categories might not be up to date
        $print_width = [ 0, 0 ];
    }
    elsif ( $category eq 'Cf' && ( $bidi_class ne 'AN' || $cust_width->{arabic_number_format_characters} == 0 ) ) {
        # Cf = Other, format
        # AN = bidi clas arbic number
        # https://www.unicode.org/versions/Unicode14.0.0/ch09.pdf # 9.2 Arabic -> Signs Spanning Numbers -> Unlike ...
        $print_width = [ 0, 0 ];
    }
    elsif ( $c >= 0x1160 && $c <= 0x11FF && $cust_width->{hangul_jamo_1160_11ff} == 0 ) {
#        # Hangul Jamo: Medial vowels, Old medial vowels, Final consonants, Old final consonants
#        # https://www.unicode.org/versions/Unicode14.0.0/ch18.pdf # 18.6 Hangul -> Hangul Jamo
#        # https://devblogs.microsoft.com/oldnewthing/20201009-00/?p=104351
        $print_width = [ 0, 0 ];
    }
    elsif ( $cust_width->{regional_indicator_symbol_letters} == 2 && $c >= 0x1f1e6 && $c <= 0x1f1ff ) {
        # Regional Indicator Symbol Letters A - Z   OtherSymbol
        $print_width = [ 2, 2 ];
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

# 0x01734  HANUNOO SIGN PAMUDPOD  SpacingMark   -> Gnome-Terminal  print width == 0



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
use 5.10.0;

our \$VERSION = '$Term::Choose::VERSION';

use Exporter qw( import );

our \@EXPORT_OK = qw( table_char_width );


# test with gnome-terminal - ambiguous characters set to $amb

# Control characters, non-characters and surrogates are removed before using this table.
# However - to have less ranges in table_char_width - surrogates and non-characters return 1.


sub table_char_width { [
|;

    my $number_of_ranges = 0;
    for my $r ( @$ranges ) {
        my $cm = '#';
        # less than 0 is \p{C}
        if ( $r->{width} >= 0 ) {
            $cm = '';
            $number_of_ranges++;
        }
        printf $fh "${cm}[%8s, %8s, %d],\n", sprintf( "0x%x", $r->{begin} ), sprintf( "0x%x", $r->{end} ), $r->{width};
    }

    print $fh "]\n}\n\n\n1;\n";
    close $fh;
}



