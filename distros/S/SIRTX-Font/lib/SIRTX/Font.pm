# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for working with SIRTX font files

package SIRTX::Font;

use v5.20;
use strict;
use warnings;

use Carp;
#use parent 'Data::Identifier::Interface::Userdata';

use constant {
    MAGIC               => pack('CCCCCCCC', 0x00, 0x07, ord('S'), ord('F'), 0x0d, 0x0a, 0xc0, 0x0a),
    DATA_START_MARKER   => 0x0600,
};

my %_char_lists = (
    'ascii'     => [0x20 .. 0x7E],
    'dec-mcs'   => [
        0x20 .. 0x7E, # ASCII
        0xA0 .. 0xA3, 0xA5, 0xA7, 0xA9, 0xAA, 0xAB,
        0xB0 .. 0xB3, 0xB5 .. 0xB7, 0xB9 .. 0xBD, 0xBF,
        0xC0 .. 0xCF,
        0xD1 .. 0xD6, 0xD8 .. 0xDC, 0xDF,
        0xE0 .. 0xEF,
        0xF1 .. 0xF6, 0xF8 .. 0xFC,
        164, 338, 376, 339, 255, # Those with special mappings
    ],
    'dec-sg'    => [
        # 0x5X:
        0x00A0,
        # 0x6X:
        0x25C6, 0x2592, 0x2409, 0x240C, 0x240D, 0x240A, 0x00B0, 0x00B1, 0x2424, 0x240B, 0x2518, 0x2510, 0x250C, 0x2514, 0x253C, 0x23BA,
        # 0x7X:
        0x23BB, 0x2500, 0x23BC, 0x23BD, 0x251C, 0x2524, 0x2534, 0x252C, 0x2502, 0x2264, 0x2265, 0x03C0, 0x2260, 0x00A3, 0x00B7,
    ],
    'dec-tech' => [
        0x0020, 0x00AC, 0x00D7, 0x00F7, 0x0192, 0x0393, 0x0394, 0x0398, 0x039B, 0x039E, 0x03A0, 0x03A3, 0x03A5, 0x03A6, 0x03A8, 0x03A9,
        0x03B1, 0x03B2, 0x03B3, 0x03B4, 0x03B5, 0x03B6, 0x03B7, 0x03B8, 0x03B9, 0x03BA, 0x03BB, 0x03BD, 0x03BE, 0x03C0, 0x03C1, 0x03C3,
        0x03C4, 0x03C5, 0x03C6, 0x03C7, 0x03C8, 0x03C9, 0x2190, 0x2191, 0x2192, 0x2193, 0x21D2, 0x21D4, 0x2202, 0x2207, 0x221A, 0x221D,
        0x221E, 0x2227, 0x2228, 0x2229, 0x222A, 0x222B, 0x2234, 0x223C, 0x2243, 0x2260, 0x2261, 0x2264, 0x2265, 0x2282, 0x2283, 0x231D,
        0x231F, 0x2320, 0x2321, 0x239B, 0x239D, 0x239E, 0x23A0, 0x23A1, 0x23A3, 0x23A4, 0x23A6, 0x23A8, 0x23AC, 0x23B2, 0x23B3, 0x23B7,
        0x2500, 0x2502, 0x250C, 0x2571, 0x2572, 0x27E9,
    ],
    'sirtx-characters' => [
        0x20AC, 0x2191, 0x2193, 0x2190,  0x2192,  0x221E, 0x2261, 0x25C4, 0x25BA, 0x2642, 0x2640, 0x263A, 0x263B, 0x2665, 0x2660, 0x2663,
        0x266A, 0x23A1, 0x23A6, 0x1F431, 0x1FBB0, 0x2026, 0x03A9, 0x231B, 0x00A4,
    ],
    'cp-850' => [
        0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027, 0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
        0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
        0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047, 0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
        0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057, 0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
        0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067, 0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
        0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077, 0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x00A0,
        0x00A1, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7, 0x00A8, 0x00A9, 0x00AA, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, 0x00B0,
        0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7, 0x00B8, 0x00B9, 0x00BA, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x00BF, 0x00C0,
        0x00C1, 0x00C2, 0x00C3, 0x00C4, 0x00C5, 0x00C6, 0x00C7, 0x00C8, 0x00C9, 0x00CA, 0x00CB, 0x00CC, 0x00CD, 0x00CE, 0x00CF, 0x00D0,
        0x00D1, 0x00D2, 0x00D3, 0x00D4, 0x00D5, 0x00D6, 0x00D7, 0x00D8, 0x00D9, 0x00DA, 0x00DB, 0x00DC, 0x00DD, 0x00DE, 0x00DF, 0x00E0,
        0x00E1, 0x00E2, 0x00E3, 0x00E4, 0x00E5, 0x00E6, 0x00E7, 0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED, 0x00EE, 0x00EF, 0x00F0,
        0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x00F5, 0x00F6, 0x00F7, 0x00F8, 0x00F9, 0x00FA, 0x00FB, 0x00FC, 0x00FD, 0x00FE, 0x00FF, 0x0131,
        0x0192, 0x2017, 0x2022, 0x203C, 0x2190, 0x2191, 0x2192, 0x2193, 0x2194, 0x2195, 0x21A8, 0x221F, 0x2302, 0x2500, 0x2502, 0x250C,
        0x2510, 0x2514, 0x2518, 0x251C, 0x2524, 0x252C, 0x2534, 0x253C, 0x2550, 0x2551, 0x2554, 0x2557, 0x255A, 0x255D, 0x2560, 0x2563,
        0x2566, 0x2569, 0x256C, 0x2580, 0x2584, 0x2588, 0x2591, 0x2592, 0x2593, 0x25A0, 0x25AC, 0x25B2, 0x25BA, 0x25BC, 0x25C4, 0x25CB,
        0x25D8, 0x25D9, 0x263A, 0x263B, 0x263C, 0x2640, 0x2642, 0x2660, 0x2663, 0x2665, 0x2666, 0x266A, 0x266B,
    ],
    'cp-437' => [
        0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027, 0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
        0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
        0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047, 0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
        0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057, 0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
        0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067, 0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
        0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077, 0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x00A0,
        0x00A1, 0x00A2, 0x00A3, 0x00A5, 0x00A7, 0x00AA, 0x00AB, 0x00AC, 0x00B0, 0x00B1, 0x00B2, 0x00B5, 0x00B6, 0x00B7, 0x00BA, 0x00BB,
        0x00BC, 0x00BD, 0x00BF, 0x00C4, 0x00C5, 0x00C6, 0x00C7, 0x00C9, 0x00D1, 0x00D6, 0x00DC, 0x00DF, 0x00E0, 0x00E1, 0x00E2, 0x00E4,
        0x00E5, 0x00E6, 0x00E7, 0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED, 0x00EE, 0x00EF, 0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x00F6,
        0x00F7, 0x00F9, 0x00FA, 0x00FB, 0x00FC, 0x00FF, 0x0192, 0x0393, 0x0398, 0x03A3, 0x03A6, 0x03A9, 0x03B1, 0x03B4, 0x03B5, 0x03C0,
        0x03C3, 0x03C4, 0x03C6, 0x2022, 0x203C, 0x207F, 0x20A7, 0x2190, 0x2191, 0x2192, 0x2193, 0x2194, 0x2195, 0x21A8, 0x2219, 0x221A,
        0x221E, 0x221F, 0x2229, 0x2248, 0x2261, 0x2264, 0x2265, 0x2302, 0x2310, 0x2320, 0x2321, 0x2500, 0x2502, 0x250C, 0x2510, 0x2514,
        0x2518, 0x251C, 0x2524, 0x252C, 0x2534, 0x253C, 0x2550, 0x2551, 0x2552, 0x2553, 0x2554, 0x2555, 0x2556, 0x2557, 0x2558, 0x2559,
        0x255A, 0x255B, 0x255C, 0x255D, 0x255E, 0x255F, 0x2560, 0x2561, 0x2562, 0x2563, 0x2564, 0x2565, 0x2566, 0x2567, 0x2568, 0x2569,
        0x256A, 0x256B, 0x256C, 0x2580, 0x2584, 0x2588, 0x258C, 0x2590, 0x2591, 0x2592, 0x2593, 0x25A0, 0x25AC, 0x25B2, 0x25BA, 0x25BC,
        0x25C4, 0x25CB, 0x25D8, 0x25D9, 0x263A, 0x263B, 0x263C, 0x2640, 0x2642, 0x2660, 0x2663, 0x2665, 0x2666, 0x266A, 0x266B,
    ],
);

$_char_lists{'cp-858'} = [map {$_ == 0x0131 ? 0x20AC : $_} @{$_char_lists{'cp-850'}}];

{
    my %important = map {$_ => undef} (0x25B2, 0x25BC, 0xFFFC, 0xFFFD); # initial values

    foreach my $list (qw(ascii dec-mcs dec-sg sirtx-characters)) {
        $important{$_} = undef foreach @{$_char_lists{$list}};
    }

    $_char_lists{important} = [map {int} keys %important];
}

my %_default_alias_lists;
$_default_alias_lists{'common-small'} = {
};
$_default_alias_lists{'common-large'} = {
    %{$_default_alias_lists{'common-small'}},
    0x00B5 => 0x03BC,   # MICRO SIGN                    -> GREEK SMALL LETTER MU
    0x037E => 0x003B,   # GREEK QUESTION MARK           -> SEMICOLON
    0x0387 => 0x00B7,   # GREEK ANO TELEIA              -> MIDDLE DOT
    0x2024 => 0x002E,   # ONE DOT LEADER                -> FULL STOP
    0x2126 => 0x03A9,   # OHM SIGN                      -> GREEK CAPITAL LETTER OMEGA
    0x212B => 0x00C5,   # ANGSTROM SIGN                 -> LATIN CAPITAL LETTER A WITH RING ABOVE
    0x2236 => 0x003A,   # RATIO                         -> COLON
    0x2666 => 0x25C6,   # BLACK DIAMOND SUIT            -> BLACK DIAMOND
    0x2665 => 0x1F5A4,  # BLACK HEART SUIT              -> BLACK HEART
    0x220E => 0x25A0,   # END OF PROOF                  -> BLACK SQUARE
    0x223C => 0x007E,   # TILDE OPERATOR                -> TILDE

    # Roman numbers:
    0x2160 => 0x0049,   # ROMAN NUMERAL ONE             -> LATIN CAPITAL LETTER I
    0x2164 => 0x0056,   # ROMAN NUMERAL FIVE            -> LATIN CAPITAL LETTER V
    0x2169 => 0x0058,   # ROMAN NUMERAL TEN             -> LATIN CAPITAL LETTER X
    0x216C => 0x004C,   # ROMAN NUMERAL FIFTY           -> LATIN CAPITAL LETTER L
    0x216D => 0x0043,   # ROMAN NUMERAL ONE HUNDRED     -> LATIN CAPITAL LETTER C
    0x216E => 0x0044,   # ROMAN NUMERAL FIVE HUNDRED    -> LATIN CAPITAL LETTER D
    0x216F => 0x004D,   # ROMAN NUMERAL ONE THOUSAND    -> LATIN CAPITAL LETTER M

    0x2170 => 0x0069,   # SMALL ROMAN NUMERAL ONE           -> LATIN SMALL LETTER I
    0x2174 => 0x0076,   # SMALL ROMAN NUMERAL FIVE          -> LATIN SMALL LETTER V
    0x2179 => 0x0078,   # SMALL ROMAN NUMERAL TEN           -> LATIN SMALL LETTER X
    0x217C => 0x006C,   # SMALL ROMAN NUMERAL FIFTY         -> LATIN SMALL LETTER L
    0x217D => 0x0063,   # SMALL ROMAN NUMERAL ONE HUNDRED   -> LATIN SMALL LETTER C
    0x217E => 0x0064,   # SMALL ROMAN NUMERAL FIVE HUNDRED  -> LATIN SMALL LETTER D
    0x217F => 0x006D,   # SMALL ROMAN NUMERAL ONE THOUSAND  -> LATIN SMALL LETTER M

    # gr_la_ru
    0x0391 => 0x0041,   # GREEK CAPITAL LETTER ALPHA    -> LATIN CAPITAL LETTER A
    0x0392 => 0x0042,   # GREEK CAPITAL LETTER BETA     -> LATIN CAPITAL LETTER B
    0x0395 => 0x0045,   # GREEK CAPITAL LETTER EPSILON  -> LATIN CAPITAL LETTER E
    0x03A1 => 0x0050,   # GREEK CAPITAL LETTER RHO      -> LATIN CAPITAL LETTER P
    0x0397 => 0x0048,   # GREEK CAPITAL LETTER ETA      -> LATIN CAPITAL LETTER H
    0x03A4 => 0x0054,   # GREEK CAPITAL LETTER TAU      -> LATIN CAPITAL LETTER T
    0x039A => 0x004B,   # GREEK CAPITAL LETTER KAPPA    -> LATIN CAPITAL LETTER K
    0x039C => 0x004D,   # GREEK CAPITAL LETTER MU       -> LATIN CAPITAL LETTER M
    0x039F => 0x004F,   # GREEK CAPITAL LETTER OMICRON  -> LATIN CAPITAL LETTER O
    0x03A7 => 0x0058,   # GREEK CAPITAL LETTER CHI      -> LATIN CAPITAL LETTER X
    0x03A5 => 0x0059,   # GREEK CAPITAL LETTER UPSILON  -> LATIN CAPITAL LETTER Y

    0x0410 => 0x0041,   # CYRILLIC CAPITAL LETTER A     -> LATIN CAPITAL LETTER A
    0x0412 => 0x0042,   # CYRILLIC CAPITAL LETTER VE    -> LATIN CAPITAL LETTER B
    0x0415 => 0x0045,   # CYRILLIC CAPITAL LETTER IE    -> LATIN CAPITAL LETTER E
    0x0420 => 0x0050,   # CYRILLIC CAPITAL LETTER ER    -> LATIN CAPITAL LETTER P
    0x041D => 0x0048,   # CYRILLIC CAPITAL LETTER EN    -> LATIN CAPITAL LETTER H
    0x0422 => 0x0054,   # CYRILLIC CAPITAL LETTER TE    -> LATIN CAPITAL LETTER T
    0x041A => 0x004B,   # CYRILLIC CAPITAL LETTER KA    -> LATIN CAPITAL LETTER K
    0x041C => 0x004D,   # CYRILLIC CAPITAL LETTER EM    -> LATIN CAPITAL LETTER M
    0x041E => 0x004F,   # CYRILLIC CAPITAL LETTER O     -> LATIN CAPITAL LETTER O
    0x0425 => 0x0058,   # CYRILLIC CAPITAL LETTER HA    -> LATIN CAPITAL LETTER X
    0x0423 => 0x0059,   # CYRILLIC CAPITAL LETTER U     -> LATIN CAPITAL LETTER Y

    # gr_la
    0x039D => 0x004E,   # GREEK CAPITAL LETTER NU       -> LATIN CAPITAL LETTER N
    0x0396 => 0x005A,   # GREEK CAPITAL LETTER ZETA     -> LATIN CAPITAL LETTER Z
    0x0399 => 0x0049,   # GREEK CAPITAL LETTER IOTA     -> LATIN CAPITAL LETTER I
    0x03B2 => 0x00DF,   # GREEK SMALL LETTER BETA       -> LATIN SMALL LETTER SHARP S
    0x03BF => 0x006F,   # GREEK SMALL LETTER OMICRON    -> LATIN SMALL LETTER O
    0x03AA => 0x00CF,   # GREEK CAPITAL LETTER IOTA WITH DIALYTIKA      -> LATIN CAPITAL LETTER I WITH DIAERESIS
    0x03AB => 0x0178,   # GREEK CAPITAL LETTER UPSILON WITH DIALYTIKA   -> LATIN CAPITAL LETTER Y WITH DIAERESIS

    # la_ru
    0x0421 => 0x0043,   # CYRILLIC CAPITAL LETTER ES    -> LATIN CAPITAL LETTER C
};
$_default_alias_lists{'common-all'} = {
    %{$_default_alias_lists{'common-large'}},
    0x00A0 => 0x0020, # NO-BREAK SPACE      -> SPACE
};

our $VERSION = v0.05;



sub new {
    my ($pkg, @args) = @_;
    my $self = bless {
        width   => undef,
        height  => undef,
        bits    => undef,
        glyphs  => [],
        chars   => {},
    }, $pkg;

    croak 'Stray options passed' if scalar @args;

    return $self;
}


sub gc {
    my ($self) = @_;
    my $chars = $self->{chars};
    my $glyphs = $self->{glyphs};
    my $new = 0;
    my %updates;
    my %dedup;

    foreach my $glyph (values %{$chars}) {
        $updates{$glyph} //= $dedup{$glyphs->[$glyph]};
        $updates{$glyph} //= $new++;
        $dedup{$glyphs->[$glyph]} = $updates{$glyph};
    }

    {
        my @n;
        my $last = -1;

        foreach my $glyph (sort {$updates{$a} <=> $updates{$b}} keys %updates) {
            next if $last == $updates{$glyph};
            $last = $updates{$glyph};
            push(@n, $glyphs->[$glyph]);
        }

        $self->{glyphs} = \@n;
    }

    foreach my $char (keys %{$chars}) {
        $chars->{$char} = $updates{$chars->{$char}};
    }

    return $self;
}


sub width {
    my ($self, $n) = @_;

    if (defined $n) {
        $n = int $n;
        croak 'Invalid width: '.$n if $n < 1 || $n > 255;
        $self->{width} = $n;
    }

    return $self->{width} // croak 'No width set';
}


sub height {
    my ($self, $n) = @_;

    if (defined $n) {
        $n = int $n;
        croak 'Invalid height: '.$n if $n < 1 || $n > 255;
        $self->{height} = $n;
    }

    return $self->{height} // croak 'No height set';
}


sub bits {
    my ($self, $n) = @_;

    if (defined $n) {
        $n = int $n;
        croak 'Invalid width: '.$n if $n < 1 || $n > 255;
        $self->{bits} = $n;
    }

    return $self->{bits} // croak 'No bits set';
}


sub codepoints {
    my ($self) = @_;
    croak 'Must be called in scalar context' if wantarray;
    return scalar keys %{$self->{chars}};
}


sub glyphs {
    my ($self) = @_;
    croak 'Must be called in scalar context' if wantarray;
    return scalar @{$self->{glyphs}};
}


sub has_codepoint {
    my ($self, $codepoint) = @_;

    $codepoint = $self->_parse_codepoint($codepoint);

    return defined $self->{chars}{$codepoint};
}


sub remove_codepoint {
    my ($self, $codepoint) = @_;

    $codepoint = $self->_parse_codepoint($codepoint);

    delete $self->{chars}{$codepoint};

    return $self;
}


sub has_all_codepoints_from {
    my ($self, @lists) = @_;

    foreach my $list (@lists) {
        foreach my $codepoint (@{$_char_lists{$list} // croak 'Unknown list: '.$list}) {
            return undef unless defined $self->{chars}{$codepoint};
        }
    }

    return 1;
}


sub missing_codepoints_from {
    my ($self, @lists) = @_;
    my %missing;

    foreach my $list (@lists) {
        foreach my $codepoint (@{$_char_lists{$list} // croak 'Unknown list: '.$list}) {
            $missing{$codepoint} = undef unless defined $self->{chars}{$codepoint};
        }
    }

    return map {int} keys %missing;
}


sub remove_codepoint_not_in {
    my ($self, @lists) = @_;
    my %required;

    foreach my $list (@lists) {
        foreach my $codepoint (@{$_char_lists{$list} // croak 'Unknown list: '.$list}) {
            $required{$codepoint} = undef;
        }
    }

    foreach my $codepoint (keys %{$self->{chars}}) {
        delete $self->{chars}{$codepoint} unless exists $required{$codepoint};
    }

    return $self;
}


sub glyph_for {
    my ($self, $codepoint, $glyph) = @_;

    $codepoint = $self->_parse_codepoint($codepoint);

    if (defined $glyph) {
        $glyph = int $glyph;
        if ($glyph < 0 || $glyph >= scalar(@{$self->{glyphs}})) {
            croak 'Invalid glyph: '.$glyph;
        }
        $self->{chars}{$codepoint} = $glyph;
    }

    return $self->{chars}{$codepoint} // croak 'Codepoint unknown: '.$codepoint;
}

sub _parse_codepoint {
    my ($self, $codepoint) = @_;

    if ($codepoint =~ /^[Uu]\+([0-9a-fA-F]{4,6})$/) {
        $codepoint = hex($1);
    } else {
        $codepoint = int($codepoint);
    }

    croak 'Unicode character out of range: '.$codepoint if $codepoint < 0 || $codepoint > 0x10FFFF;

    return $codepoint;
}


sub default_glyph_for {
    my ($self, $codepoint, $glyph) = @_;

    $codepoint = $self->_parse_codepoint($codepoint);

    return $self->{chars}{$codepoint} if defined $self->{chars}{$codepoint};
    return $self->glyph_for($codepoint, $glyph);
}


sub alias_glyph {
    my ($self, $from, $to) = @_;
    $self->glyph_for($to, $self->glyph_for($from));
    return $self;
}


sub default_alias_glyph {
    my ($self, $from, $to) = @_;
    $self->default_glyph_for($to, $self->glyph_for($from));
    return $self;
}


sub add_default_aliases {
    my ($self, $level) = @_;
    my $chars = $self->{chars};

    $level //= 'common-small';
    $level = $_default_alias_lists{$level} // croak 'Unknown alias level: '.$level;

    # This is a three pass process:
    # * first add all forward aliases
    # * second add all reverse aliases
    # * thrid add all forward aliases again,
    #   as with the back aliases we might have new ones

    # Add forward aliases:
    $chars->{$_} //= $chars->{$level->{$_}} foreach keys %{$level};

    # Add backwards aliases:
    $chars->{$level->{$_}} //= $chars->{$_} foreach keys %{$level};

    # Retry: Add forward aliases:
    $chars->{$_} //= $chars->{$level->{$_}} foreach keys %{$level};

    return $self;
}


sub read {
    my ($self, $in) = @_;
    my $chars = $self->{chars};
    my $glyphs = $self->{glyphs};
    my $offset = scalar @{$glyphs};
    my ($marker, $w, $h, $b, $count);
    my $entry_size;
    local $/ = \8;

    $in->binmode;

    croak 'Bad magic' unless scalar(<$in>) eq MAGIC;
    ($marker, $w, $h, $b, $count) = unpack('nCCCxn', scalar(<$in>));
    croak 'Bad marker' unless $marker == DATA_START_MARKER;
    croak 'Bits value is not 1' unless $b == 1;

    $self->width($w);
    $self->height($h);
    $self->bits($b);

    $entry_size = (int($w / 8) + ($w & 0x7 ? 1 : 0)) * $h;

    while (defined(my $data = <$in>)) {
        my ($char, $len, $glyph) = unpack('Nnn', $data);
        last if $char == 0xFFFFFFFF;

        for (my $i = 0; $i <= $len; $i++) {
            $chars->{$char+$i} = $glyph + $offset + $i;
        }
    }

    $/ = \$entry_size;

    while (defined(my $data = <$in>)) {
        croak 'Short read' unless length($data) == $entry_size;
        push(@{$glyphs}, $data);
    }

    return $self;
}


sub write {
    my ($self, $out) = @_;
    my $chars = $self->{chars};
    my $glyphs = $self->{glyphs};
    my %index;
    my @list = sort {$a <=> $b} keys %{$chars};
    my %index_update;
    my @runs;

    {
        my $next_index = 0;
        my $run;

        foreach my $idx (@list) {
            my $glyph = $index_update{$chars->{$idx}} //= $next_index++;

            if (defined $run) {
                my $next = $run->[1] + 1;
                if ($idx == ($run->[0] + $next) && $glyph == ($run->[2] + $next)) {
                    $run->[1]++;
                } else {
                    $run = undef;
                    redo;
                }
            } else {
                push(@runs, $run = [$idx, 0, $glyph]);
            }
        }

    }

    $out->binmode;

    print $out MAGIC;
    print $out pack('nCCCxn', DATA_START_MARKER, $self->width, $self->height, $self->bits, scalar(keys %index_update));
    print $out pack('Nnn', @{$_}) foreach @runs;
    print $out pack('Nnn', 0xFFFFFFFF, 0, 0);

    foreach my $glyph (sort {$index_update{$a} <=> $index_update{$b}} keys %index_update) {
        print $out $glyphs->[$glyph];
    }
}


sub import_glyph {
    my ($self, $in) = @_;

    if (!eval {$in->isa('Image::Magick')}) {
        require Image::Magick;
        my $p = Image::Magick->new;
        $p->Read($in);
        $in = $p;
    }

    return $self->_import_glyph_wbmp($in->ImageToBlob(magick => 'wbmp'));
}

sub _import_glyph_wbmp {
    my ($self, $data) = @_;
    my ($w, $h);

    croak 'Bad wbmp magic' unless substr($data, 0, 2) eq "\0\0";
    ($w, $h) = unpack('CC', substr($data, 2, 2));

    croak 'Bad geometry' if ($w & 0x80) || ($h & 0x80);

    $self->width($w);
    $self->height($h);
    $self->bits(1);

    push(@{$self->{glyphs}}, substr($data, 4));

    return scalar(@{$self->{glyphs}}) - 1;
}


sub import_alias_map {
    my ($self, $filename, %opts) = @_;
    my $chars = $self->{chars};

    croak 'Stray options passed' if scalar keys %opts;

    open(my $in, '<:utf8', $filename) or croak 'Cannot open: '.$filename.': '.$!;
    while (defined(my $line = <$in>)) {
        my ($pg, $sg);
        my $primary;

        $line =~ s/\r?\n$//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $line =~ s/^(?:;|\/\/|#).*$//;
        $line =~ s/\s+/ /g;

        ($pg, $sg) = $line =~ /^(.+?\S)(?:\s+(?:--|<-|->|=>|<=)\s+(\S.+))?$/;

        croak 'Invalid format' unless defined $pg;

        $_ = [map {$self->_parse_codepoint($_)} grep {length} split/\s*,\s*|\s+/, $_ // ''] foreach $pg, $sg;

        croak 'Invalid primary list: list is empty' unless scalar @{$pg};

        # Alias all of primary, and then primary to secondary.
        foreach my $char (@{$pg}) {
            $primary //= $chars->{$char};
        }
        if (defined $primary) {
            $chars->{$pg->[0]} = $primary;
            foreach my $char (@{$pg}, @{$sg}) {
                $chars->{$char} //= $primary;
            }
        }
    }

    return $self;
}


sub import_directory {
    my ($self, $directory, %opts) = @_;
    my $chars = $self->{chars};
    my $incremental = delete $opts{incremental};

    require File::Spec;

    croak 'Stray options passed' if scalar keys %opts;

    opendir(my $dir, $directory) or croak 'Cannot open directory: '.$directory;
    while (defined(my $ent = readdir($dir))) {
        if ($ent =~ /^U\+([0-9A-F]{4,})\.(?:png|wbmp)$/) {
            my $codepoint = hex $1;
            my $fullname;
            my $glyph;

            next if $incremental && defined $chars->{$codepoint};

            $fullname = File::Spec->catfile($directory, $ent);
            # TODO: Handle symlinks here.
            $glyph = $self->import_glyph($fullname);
            $self->glyph_for($codepoint => $glyph);
        }
    }
    closedir($dir);

    return $self;
}


sub export_glyph_as_image_magick {
    my ($self, $glyph) = @_;
    my $p;

    $glyph = int($glyph) if defined $glyph;
    croak 'No valid glyph given' unless defined($glyph) && $glyph >= 0;
    $glyph = $self->{glyphs}[$glyph];
    croak 'No valid glyph given' unless defined($glyph);

    if ($self->width >= 128 || $self->height >= 128 || $self->bits != 1) {
        croak 'Unsupported glyph size';
    }

    require Image::Magick;
    $p = Image::Magick->new(magick => 'wbmp');
    $p->BlobToImage(pack('CCCC', 0, 0, $self->width, $self->height).$glyph);

    return $p;
}


sub export_alias_map {
    my ($self, $filename, %opts) = @_;
    my $chars = $self->{chars};
    my %glyph_map;
    local $, = ' ';

    croak 'Stray options passed' if scalar keys %opts;

    foreach my $char (keys %{$chars}) {
        push(@{$glyph_map{$chars->{$char}} //= []}, $char);
    }

    open(my $out, '>:utf8', $filename) or croak 'Cannot open file: '.$filename.': '.$!;

    foreach my $chars (grep {scalar(@{$_}) > 1} values %glyph_map) {
        $out->say(map {sprintf('U+%04X', $_)} sort {$a <=> $b} @{$chars});
    }
}


sub render {
    require List::Util;
    require Image::Magick;

    my ($self, $string) = @_;
    my @lines = split(/\r?\n/, $string);
    my $max_line = List::Util::max(map {length} @lines);
    my $width = $self->width;
    my $height = $self->height;
    my $p = Image::Magick->new;
    my %handle_cache;

    $p->Set(size => sprintf('%ux%u', $max_line * $width, scalar(@lines) * $height));
    $p->Read('canvas:white');

    for (my $row = 0; $row < scalar(@lines); $row++) {
        my $line = $lines[$row];
        my $len  = length($line);

        for (my $column = 0; $column < $len; $column++) {
            my $c = substr($line, $column, 1);
            my $handle = $handle_cache{ord $c} //= $self->export_glyph_as_image_magick($self->glyph_for(ord $c));
            $p->CopyPixels(image => $handle, width => $width, height => $height, x => 0, y => 0, dx => $column * $width, dy => $row * $height);
        }
    }

    return $p;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::Font - module for working with SIRTX font files

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use SIRTX::Font;

    my SIRTX::Font $font = SIRTX::Font->new;

    $font->read('cool-font.sf');
    $font->write('cool-font.sf');

    if ($font->has_codepoint(0x1234)) { ... }

    printf("%ux%u\@%u\n", $font->width, $font->height, $font->bits);

    $font->glyph_for(0x1234, $font->import_glyph('U+1234.png'));

This module implements an interface to SIRTX font files.

All methods in this module C<die> on error unless documented otherwise.

=head1 CHARACTER LISTS

This module includes a few methods that use named character lists.
There refer to one or more of the build-in charater lists.

Currently defined:

=over

=item C<ascii>

All printable ASCII characters.

=item C<dec-mcs>

All printable characters in DEC-MCS (Multinational Character Set).

=item C<dec-sg>

All printable characters in DEC-SG (Special Graphics).

=item C<dec-tech>

All printable characters in DEC Technical.

=item C<sirtx-characters>

All characters in the SIRTX character list (provided by SIRTX on old non-Unicode terminals that support DLLCS).

=item C<important>

Characters that are considered important in the context of SIRTX.
Each base font SHOULD provide at least those characters.
This also includes entries from at least C<dec-mcs>, C<dec-sg>, and C<sirtx-characters>, but may contain more.

=item C<cp-850>

Code page 850 (often used on classic DOS systems).

=item C<cp-858>

Code page 858 (often used on more modern DOS systems).

=item C<cp-437>

Code page 437 (original IBM PC character set).

=back

=head1 METHODS

=head2 new

    my SIRTX::Font $font = SIRTX::Font->new;

Creates a new font object. No parameters are supported.

=head2 gc

    $font->gc;

(experimental)

Takes the trash out. This will remove unused glyphs and deduplicate glyphs that are still in use.

B<Note:>
After a call to this all glyph numbers become invalid.

=head2 width

    $font->width($width);

    my $width = $font->width;

Sets or gets the width of character cells.

=head2 height

    $font->height($height);

    my $height = $font->height;

Sets or gets the height of character cells.

=head2 bits

    $font->bits($bits);

    my $bits = $font->bits;

Sets or gets the bits per pixel of character cells.

=head2 codepoints

    my $codepoints = $font->codepoints;

Returns the number of known code points.

B<Note:>
Must be called in scalar context.

=head2 glyphs

    my $glyphs = $font->glyphs;

Returns the number of known glyphs.

B<Note:>
This is not the number of glyphs that is exported on write,
as unused glyphs might be skipped.

B<Note:>
Must be called in scalar context.

=head2 has_codepoint

    my $bool = $font->has_codepoint($codepoint);

Returns a true value if the code point is knowm, otherwise return a false value.

=head2 remove_codepoint

    $font->remove_codepoint(0x1234);

Removes a code point from the font.
This will not remove the glyph.

If the code point is not known this method will do nothing.

=head2 has_all_codepoints_from

    my $bool = $font->has_all_codepoints_from( @lists );
    # e.g.:
    my $bool = $font->has_all_codepoints_from('important');
    my $bool = $font->has_all_codepoints_from(qw(dec-mcs dec-sg));

Returns a true value if all code points from the given lists are included, otherwise false.

B<Note:>
This is faster than calling L</missing_codepoints_from> and checking if it returned any items.

=head2 missing_codepoints_from

    my @codepoints = $font->missing_codepoints_from( @lists );
    # e.g.:
    my @codepoints = $font->missing_codepoints_from('important');

Returns the code points missing from the given lists that are missing in this font.

B<Note:>
If you only want to check if all code points are included use L</has_all_codepoints_from> which is faster.

=head2 remove_codepoint_not_in

    $font->remove_codepoint_not_in( @lists );
    # e.g.:
    $font->remove_codepoint_not_in('dec-mcs');

Removes all code points from the current font that are not in the given lists.
This can be used to strip a larger font to a subset efficiently.

B<Note:>
This will only remove the code points, not the glyphs as per L</remove_codepoint>.

=head2 glyph_for

    my $glyph = $font->glyph_for($codepoint); # $codepoint is 0x1234 or 'U+1234'

    $font->glyph_for($codepoint => $glyph);

Sets or gets the glyph for a given code point.

=head2 default_glyph_for

    $glyph = $font->default_glyph_for($codepoint => $glyph);

Sets the glyph for the code point if it has no glyph set so far.
Returns the new glyph (if the code point was modified) or the old (if it was already set).

=head2 alias_glyph

    $font->alias_glyph($from, $to);

Aliases the glyph for code point C<$from> to the same as code point C<$to>.

See also L</glyph_for>.

=head2 default_alias_glyph

    $font->default_alias_glyph($from, $to);

Aliases the glyph for code point C<$from> to the same as code point C<$to> if C<$from> has no glyph set.

=head2 add_default_aliases

    $font->add_default_aliases;
    # or:
    $font->add_default_aliases($level);

(experimental)

Adds aliases as per L</default_alias_glyph> for known homoglyphs.

The following levels are supported:

=over

=item C<common-small>

A set if code point aliases that are both likely homoglyphs as well as hard to pick up by rendering engines.

=item C<common-large>

A set of code point aliases that are likely homoglyphs, some might be picked up by rendering engines.
This includes the aliases from C<common-small>.

=item C<common-all>

A set of code point aliases that are likely homoglyphs, including those that should be picked up by rendering engines.
This includes the aliases from C<common-small>, and C<common-large>.

=back

B<Note:>
This operation cannot easly be undone.

B<Note:>
The levels are not yet stable in this version. Future versions might use different sets of code points aliases.

=head2 read

    $font->read($handle);

Reads a font file into memory.
If any data is already loaded the data is merged.

=head2 write

    $font->write($handle);

Writes the current font in the SIRTX format to the given handle.

=head2 import_glyph

    my $glyph = $font->import_glyph($filename);

Imports a glyph from a file.
The glyph index is returned.

The supported formats depend on the installed modules.
See also L<Image::Magick>.

=head2 import_alias_map

    $font->import_alias_map($filename);

(experimental)

Imports an alias map from the given file.

The format is one alias group per line.
Each line is formatted into two sections.
The first section lists all the code points that are aliased to each other.
The second part (seperated by a C<-->) lists all the code points that
are only aliased to (that is they will share the glyph from the first part,
but the code points from the first part will not share glyph with the second part).

Each part is a list of codepoints in C<U+NNNN> format, seperated by space, comma or both.

This method will ignore if a mapped glyph does not exists alike L</default_glyph_for>.

=head2 import_directory

    $font->import_directory($filename [, %opts ]);

(experimental)

Imports a directory into the font.
The directory contains of files with a name of the code point plus the extention png or wbmp (e.g. C<U+1F981.png>).

There is one option supported: C<incremental>.
If set to a true value it will cause mappings for already known code points to be skipped.
This can result in a massive speedup.
Only use if you are sure no entries have been altered.

B<Note:>
All rules of L</import_glyph> apply.
Entries are merged, data already present in the font is not cleared.

B<Note:>
In order to deduplicate entries a call to L</gc> might be considered.

=head2 export_glyph_as_image_magick

    my Image::Magick $image = $font->export_glyph_as_image_magick($glyph);

(experimental)

Exports a single glyph as a image object.

=head2 export_alias_map

    $self->export_alias_map($filename);

(experimental)

Exports the map of all aliases found in the font.
This is the inverse of L</import_alias_map>.

B<Note:>
This method cannot know which code points are aliases one way and which are aliased both ways.
This information is not included in the binary format.
Therefore this method exports all aliases as both way aliases.
This is the same behaviour as known from hardlinks.

=head2 render

    my Image::Magick $image = $font->render($string);
    # e.g.:
    my Image::Magick $image = $font->render("Hello World!");
    $image->Transparent(color => 'white'); # transparent background
    $image->Write('hello.png');

(experimental)

Renders a text using the loaded font.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
