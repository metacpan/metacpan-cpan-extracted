# Copyright (c) 2025-2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for working with SIRTX font files

package SIRTX::Font;

use v5.20;
use strict;
use warnings;
use feature 'bitwise';

use Carp;
use List::Util qw(none);
use Data::Identifier;
use Data::Identifier::Util v0.23;
use SIRTX::Datecode;
use Encode ();

#use parent 'Data::Identifier::Interface::Userdata';

use constant UTF_8 => Encode::find_encoding('UTF-8');

use constant {
    MAGIC                   => pack('CCCCCCCC', 0x00, 0x07, ord('S'), ord('F'), 0x0d, 0x0a, 0xc0, 0x0a),
    DATA_BIT                => 0x40,
    DATA_START_MARKER       => 0x0600,
    HEADER_MASTER           => 0x00,
    HEADER_EARLY_HINTS      => 0x81,
    HEADER_GEOMETRY_HINTS   => 0x82,
    HEADER_IDENTIFIER       => 0xC3,
    HEADER_DISPLAYINFO      => 0x84,
};

my %_metadata_types = (
    (map {$_ => 'uint'}
        qw(width height bits),
        qw(baseline vmiddleline hmiddleline),
        qw(version_major version_minor),
    ),
    version_type        => ['devel',  'beta',   'rc',      'stable'],
    weight              => ['normal', 'bold',   'thin',    'other'],
    slant               => ['roman',  'italic', 'oblique', 'other'],
    reverse_slant       => 'bool',
    last_modification   => 'SIRTX::Datecode',
    font_tag            => 'Data::Identifier',
    font_name           => 'string',
    icontext            => 'codepoint',
    displaycolour       => 'Data::Identifier',
);

my %_glyph_metadata_types = (
    resync              => 'bool',
    nomod               => 'bool',
    preskip             => 'uint',
    postskip            => 'uint',
);

my %_metadata_constrains = (
    (
        # base values:
        map {$_ => [
            ['>',   0],
            ['<', 256],
        ]}
        qw(width height bits),
    ),
    baseline => [
        ['>',   0],
        ['>', 'vmiddleline'],
        ['<', 'height'],
    ],
    vmiddleline => [
        ['>',   0],
        ['<', 'height'],
    ],
    hmiddleline => [
        ['>',   0],
        ['<', 'width'],
    ],
    version_major => [['<', 256]],
    version_minor => [['<',  64]],
);

my %_glyph_metadata_constrains = (
    preskip => [
        ['<', 4],
        ['<', ':width'],
    ],
    postskip => [
        ['<', 15],
        ['<', ':width'],
    ],
);

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
        0xFFFD, 0xFFFC, 0x25B2, 0x25BC,
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
    my %important = map {$_ => undef} (); # initial values

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

my %_drawing_single = (
    l       => 0x2574,
    t       => 0x2575,
    r       => 0x2576,
    b       => 0x2577,
    tb      => 0x2502,
    lr      => 0x2500,
    br      => 0x250C,
    bl      => 0x2510,
    tr      => 0x2514,
    tl      => 0x2518,
    tbr     => 0x251C,
    tbl     => 0x2524,
    blr     => 0x252C,
    tlr     => 0x2534,
    tblr    => 0x253C,
);

my %_ttf_encodings = (
    1 => {
        0 => 'MACINTOSH',
    },
    3 => {
        0 => 'UCS-2', # Symbol !?!?
        1 => 'UCS-2',
    },
);

our $VERSION = v0.08;



sub new {
    my ($pkg, @args) = @_;
    my $self = bless {
        width       => undef,
        height      => undef,
        bits        => undef,
        glyphs      => [],
        glyph_attr  => [],
        chars       => {},
        util        => Data::Identifier::Util->new,
    }, $pkg;

    croak 'Stray options passed' if scalar @args;

    return $self;
}


sub gc {
    my ($self) = @_;
    my $chars = $self->{chars};
    my $glyphs = $self->{glyphs};
    my $glyph_attr = $self->{glyph_attr};
    my $new = 0;
    my %updates;
    my %dedup;
    my %attr;

    for (my $glyph = 0; $glyph < scalar(@{$glyphs}); $glyph++) {
        if (defined $glyph_attr->[$glyph]) {
            my $attr = $attr{$glyphs->[$glyph]} //= {};
            %{$attr} = (%{$attr}, %{$glyph_attr->[$glyph]});
        }
    }

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

        $glyphs = $self->{glyphs} = \@n;
    }

    foreach my $char (keys %{$chars}) {
        $chars->{$char} = $updates{$chars->{$char}};
    }

    @{$glyph_attr} = ();
    for (my $glyph = 0; $glyph < scalar(@{$glyphs}); $glyph++) {
        $glyph_attr->[$glyph] = $attr{$glyphs->[$glyph]} // next;
    }

    return $self;
}

sub _check_constrains {
    my ($self, $glyph) = @_;
    my $constrains;
    my $source;

    if (defined $glyph) {
        $constrains = \%_glyph_metadata_constrains;
        $source = $self->{glyph_attr}[$glyph];
    } else {
        $constrains = \%_metadata_constrains;
        $source = $self;
    }

    foreach my $key (keys %{$constrains}) {
        my $v = $source->{$key} // next;
        foreach my $constraint (@{$constrains->{$key}}) {
            my ($cmp, $ref) = @{$constraint};
            my $res;

            if ($ref =~ /^[0-9]+\z/) {
                $ref = int($ref);
            } elsif ($ref =~ /^:(.+)\z/) {
                $ref = $self->{$1} // next;
            } else {
                $ref = $source->{$ref} // next;
            }

            if ($cmp eq '<') {
                $res = $v < $ref;
            } elsif ($cmp eq '<=') {
                $res = $v <= $ref;
            } elsif ($cmp eq '>') {
                $res = $v > $ref;
            } elsif ($cmp eq '>=') {
                $res = $v >= $ref;
            } elsif ($cmp eq '==') {
                $res = $v == $ref;
            }

            unless ($res) {
                croak sprintf('Constraint failed: %s %s %s is false', $key, @{$constraint});
            }
        }
    }

    return 1;
}

sub _set_value {
    my ($self, $key, $value, $glyph) = @_;
    my $type;
    my $old;

    if (defined $glyph) {
        $type = $_glyph_metadata_types{$key // croak 'No key given'};
        $old = $self->{glyph_attr}[$glyph]{$key};
    } else {
        $type = $_metadata_types{$key // croak 'No key given'};
        $old = $self->{$key};
    }

    if ($key =~ s/:rgb\z//) {
        require Data::Identifier::Generate;
        $value = Data::Identifier::Generate->colour($value);
    }

    croak 'Not a valid key: '.$key unless defined $type;
    croak 'No value given' unless defined $value;

    if ($type eq 'uint') {
        croak 'Not a valid value for key: '.$key.': '.$value unless $value =~ /^(?:0|[1-9][0-9]*)\z/;
        $value = int($value);
    } elsif ($type eq 'bool') {
        $value = lc($value);
        $value = 0 if $value eq 'no' || $value eq 'nein' || $value eq 'false' || $value eq 'off';
        $value = $value ? 1 : 0;
    } elsif ($type eq 'string') {
        $value =~ s/^\s+//;
        $value =~ s/\s+\z//;
        if (length($value) == 0) {
            croak 'Not a valid string: string is empty';
        }
    } elsif ($type eq 'codepoint') {
        $value = $self->_parse_codepoint($value);
    } elsif (ref $type) {
        croak 'Value not part of enum: '.$key.': '.$value if none {$_ eq $value} @{$type};
    } elsif (eval {$value->isa($type)}) {
        # all good.
    } elsif ($type eq 'Data::Identifier' && !eval{$value->isa('Data::Identifier')}) {
        $value = Data::Identifier->new(from => $value);
    } else {
        croak 'BUG';
    }

    if (defined $glyph) {
        $self->{glyph_attr}[$glyph]{$key} = $value;
    } else {
        $self->{$key} = $value;
    }
    unless (eval {$self->_check_constrains($glyph)}) {
        if (defined $glyph) {
            $self->{glyph_attr}[$glyph]{$key} = $old;
        } else {
            $self->{$key} = $old;
        }
        die $@;
    }
}


sub width {
    my ($self, $n) = @_;

    $self->_set_value(width => $n) if defined $n;

    return $self->{width} // croak 'No width set';
}


sub height {
    my ($self, $n) = @_;

    $self->_set_value(height => $n) if defined $n;

    return $self->{height} // croak 'No height set';
}


sub bits {
    my ($self, $n) = @_;

    $self->_set_value(bits => $n) if defined $n;

    return $self->{bits} // croak 'No bits set';
}


sub list_attributes {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return keys %_metadata_types;
}


sub get_attribute {
    my ($self, $key, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    croak 'No key given' unless defined $key;
    croak 'No such key' unless defined $_metadata_types{$key};

    return $self->{$key} // croak 'No value set';
}


sub set_attribute {
    my ($self, $key, $value, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $self->_set_value($key, $value);
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

    # The above might have added undef values, so remove them now:
    delete $chars->{$_} foreach grep {!defined($chars->{$_})} keys %{$chars};

    return $self;
}


sub get_glyph_attribute {
    my ($self, $glyph, $key, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    croak 'No glyph given' unless defined $glyph;
    croak 'Invalid glyph given' if $glyph < 0 || $glyph >= scalar(@{$self->{glyphs}});
    croak 'No key given' unless defined $key;
    croak 'No such key' unless defined $_glyph_metadata_types{$key};
    croak 'No such glyph' unless exists $self->{glyph_attr}[$glyph];

    return $self->{glyph_attr}[$glyph]{$key} // croak 'No value set';
}


sub set_glyph_attribute {
    my ($self, $glyph, $key, $value, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $self->_set_value($key, $value, $glyph);
}

sub read {
    my ($self, $in) = @_;
    my $chars = $self->{chars};
    my $glyphs = $self->{glyphs};
    my $offset = scalar @{$glyphs};
    my $bits;
    my $count;
    my $entry_size;
    local $/ = \8;

    $in->binmode;

    croak 'Bad magic' unless scalar(<$in>) eq MAGIC;

    # Read headers, one at a time:
    while (defined(my $header = <$in>)) {
        my ($marker, $va, $vb, $vc, $type, $vx) = unpack('nCCCCn', $header);
        my $extra;

        croak 'Bad marker' unless $marker == DATA_START_MARKER;

        if ($type & 0x40) {
            my $len = 8 * $vc;
            my $got;

            if ($len) {
                read($in, $extra, $len);
            } else {
                $extra = '';
            }

            $got = length($extra);
            croak sprintf('Cannot read extra from header: got %u, expected %u', $got, $len) if $got != $len;
        }

        if ($type == HEADER_MASTER) {
            $self->width($va);
            $self->height($vb);
            $self->bits($vc);
            $count = $vx;
            last; # Master header is always the last one, in fact it marks the end of the header section
        } elsif ($type == HEADER_EARLY_HINTS) {
            $self->width($va);
            $self->height($vb);
            $self->_apply_font_flags($vx);
        } elsif ($type == HEADER_GEOMETRY_HINTS) {
            $self->set_attribute(hmiddleline => $va);
            $self->set_attribute(vmiddleline => $vb);
            $self->set_attribute(baseline    => $vc);
            $self->_apply_font_flags($vx);
        } elsif ($type == HEADER_IDENTIFIER) {
            $self->set_attribute(version_major => $va);
            $self->set_attribute(version_minor => $vb >> 2);

            if (($vb & 0x3) == 3) {
                $self->set_attribute(version_type => 'stable');
            } elsif (($vb & 0x3) == 2) {
                $self->set_attribute(version_type => 'rc');
            } elsif (($vb & 0x3) == 1) {
                $self->set_attribute(version_type => 'beta');
            } elsif (($vb & 0x3) == 0) {
                $self->set_attribute(version_type => 'devel');
            }

            $self->set_attribute(last_modification => SIRTX::Datecode->new(datecode => $vx)) if $vx;

            if (length($extra) >= 16) {
                my $uuid = substr($extra, 0, 16);
                $self->set_attribute(font_tag => $self->{util}->unpack(uuid128 => $uuid)) if $uuid ne (chr(0) x 16);
            }

            if (length($extra) > 16) {
                my $name = substr($extra, 16);
                $name =~ s/[\0\xff]+\z//;
                $self->set_attribute(font_name => UTF_8->decode($name));
            }
        } elsif ($type == HEADER_DISPLAYINFO || $type == (HEADER_DISPLAYINFO|DATA_BIT)) {
            my $icontext = ($va << 8) | $vb;
            my $displaycolour = $vx != 0 && $vx != 0xFFFF ? eval {
                require Data::Identifier::Wellknown;
                Data::Identifier::Wellknown->import(':all');
                $self->{util}->unpack('4+12', pack('n', $vx));
            } : undef;
            $self->set_attribute(icontext => $icontext) if $icontext != 0 && $icontext < 0xFFFD; # We exclude some extra characters here as well, as they might be an error.
            $self->set_attribute(displaycolour => $displaycolour) if defined $displaycolour;

            if (length($extra) >= 8) {
                my ($eic, $ergb) = unpack('NN', $extra);

                $self->set_attribute(icontext => $eic) if $eic <= 0x10FFFF;

                if ($ergb <= 0xFFFFFF) {
                    require Data::Identifier::Generate;
                    $self->set_attribute(displaycolour => Data::Identifier::Generate->colour('#'.unpack('H6', substr($extra, 5, 3))));
                }
            }
        } elsif ($type & 0x80) {
            carp sprintf('Unsupported optional header type: 0x%02X', $type);
        } else {
            croak sprintf('Unsupported header type: 0x%02X', $type);
        }
    }

    croak 'No Master header found' unless defined $count;
    croak 'Bits value is not 1' unless $self->bits == 1;

    {
        my $w = $self->width;
        my $h = $self->height;
        $entry_size = (int($w / 8) + ($w & 0x7 ? 1 : 0)) * $h;
    }

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
    my @extra_headers;

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

    $self->set_attribute(last_modification => SIRTX::Datecode->now);

    push(@extra_headers, eval { $self->_render_geometry_hints });
    push(@extra_headers, eval { $self->_render_identity });
    push(@extra_headers, eval { $self->_render_displayinfo });
    @extra_headers = grep {defined} @extra_headers;

    $out->binmode;

    # Write magic:
    print $out MAGIC;
    eval { print $out $self->_render_early_hints(scalar(@extra_headers)) } if scalar(@extra_headers);
    print $out $_ foreach @extra_headers;
    # Write master header:
    print $out pack('nCCCxn', DATA_START_MARKER, $self->width, $self->height, $self->bits, scalar(keys %index_update));
    # Write codepoint -> glyph map:
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

sub _read_kv_file {
    my ($self, $filename, $cb) = @_;

    open(my $in, '<:utf8', $filename) or croak 'Cannot open: '.$filename.': '.$!;
    while (defined(my $line = <$in>)) {
        my ($pg, $sg);

        $line =~ s/\r?\n$//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $line =~ s/^(?:;|\/\/|#).*$//;
        $line =~ s/\s+/ /g;

        ($pg, $sg) = $line =~ /^(.+?\S)(?:\s+(?:--|<-|->|=>|<=|=)\s+(\S.*))?$/;

        croak 'Invalid format' unless defined $pg;

        $cb->($pg, $sg);

    }

    return $self;
}


sub import_alias_map {
    my ($self, $filename, %opts) = @_;
    my $chars = $self->{chars};

    croak 'Stray options passed' if scalar keys %opts;

    $self->_read_kv_file($filename => sub {
            my ($pg, $sg) = @_;
            my $primary;

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
        });

    return $self;
}


sub import_attributes {
    my ($self, $filename, %opts) = @_;

    croak 'Stray options passed' if scalar keys %opts;

    return $self->_read_kv_file($filename, sub {
            my ($pg, $sg) = @_;
            $self->set_attribute($pg, $sg);
        });
}


sub import_font {
    my ($self, $type, $in, %opts) = @_;

    croak 'No type given' unless defined $type;
    croak 'No input given' unless defined $in;

    if ($type eq 'auto' && !ref($in)) {
        if ($in =~ m#\.(sf|psf|hex|ttf)((?:\.gz)?)\z#) {
            $type = $1;
        } elsif ($in =~ m#[/\\][Uu]\+([0-9a-fA-F]{4,6})\.[^\.]+\z#) {
            $opts{codepoint} = hex $1;
            $type = 'glyph';
        }
    }

    $type = 'sf' if $type eq 'auto';

    if ($type eq 'psf') {
        return $self->import_psf($in, %opts);
    } elsif ($type eq 'hex') {
        return $self->import_hex($in, %opts);
    } elsif ($type eq 'sf') {
        croak 'Stray options passed' if scalar keys %opts;

        if (!ref $in) {
            my $gz = $in =~ /\.gz\z/;
            my $fh;

            open($fh, '<', $in) or croak $!;
            $fh->binmode;
            $fh->binmode('gzip') if $gz;
            $in = $fh;
        }

        return $self->read($in);
    } elsif ($type eq 'glyph') {
        my $codepoint = delete($opts{codepoint}) // croak 'No codepoint given';
        my $glyph;

        croak 'Stray options passed' if scalar keys %opts;

        $glyph = $self->import_glyph($in);
        $self->glyph_for($codepoint => $glyph);
    } elsif ($type eq 'ttf') {
        return $self->_import_ttf($in, %opts);
    } else {
        croak 'Unknown type given: '.$type;
    }
}


#@deprecated
sub import_psf {
    my ($self, $in, %opts) = @_;
    my $first = scalar(@{$self->{glyphs}});
    my $chars = $self->{chars};
    my $data;

    croak 'Stray options passed' if scalar keys %opts;

    if (!ref $in) {
        my $gz = $in =~ /\.gz$/;
        my $fh;

        open($fh, '<', $in) or croak $!;
        $fh->binmode;
        $fh->binmode('gzip') if $gz;
        $in = $fh;
    }

    croak 'Cannot read magic' if $in->read($data, 2) != 2;

    if ($data eq pack('v', 0x0436)) {
        my ($mode, $height);
        my $glyphs;

        croak 'Cannot read header' if $in->read($data, 2) != 2;
        ($mode, $height) = unpack('CC', $data);

        $self->bits(1);
        $self->width(8);
        $self->height($height);

        $glyphs = $mode & 0x01 ? 512 : 256;

        for (my $i = 0; $i < $glyphs; $i++) {
            croak 'Cannot read glyph' if $in->read($data, $height) != $height;
            push(@{$self->{glyphs}}, ~. $data);
        }

        if ($mode & 0x06) {
            # we have a unicode table...
            my $cc = 0;

            while ($in->read($data, 2) == 2) {
                $data = unpack('v', $data);

                if ($data == 0xFFFF) {
                    $cc++ if $cc < $glyphs;
                } else {
                    #printf("0x%04x\n", $data) if $data > 0xFF00;
                    $chars->{$data} = $first + $cc;
                }
            }
        } else {
            carp 'No Unicode mapping table found. Gylphs will likely end up at wrong code points';

            for (my $i = 0; $i < $glyphs; $i++) {
                $chars->{$i} = $first + $i;
            }
        }
    } elsif ($data eq pack('v', 0xb572)) {
        my ($magic2, $version, $headersize, $flags, $numglyph, $bytesperglyph, $height, $width);

        croak 'Cannot read magic part two' if $in->read($data, 2 + 7*4) != (2 + 7*4);
        ($magic2, $version, $headersize, $flags, $numglyph, $bytesperglyph, $height, $width) = unpack('vVVVVVVV', $data);

        croak 'Bad magic part two'  if $magic2      != 0x864a;
        croak 'Bad version'         if $version     != 0;
        croak 'Bad headersize'      if $headersize  != 32;

        $self->bits(1);
        $self->width($width);
        $self->height($height);

        for (my $i = 0; $i < $numglyph; $i++) {
            croak 'Cannot read glyph' if $in->read($data, $bytesperglyph) != $bytesperglyph;
            push(@{$self->{glyphs}}, ~. $data);
        }

        if ($flags) {
            my $cc = 0;
            local $/ = chr(0xFF);

            while (defined(my $entry = <$in>)) {
                substr($entry, -1, 1, '');
                $chars->{ord($_)} = $first + $cc for split //, UTF_8->decode($entry);
                $cc++;
            }
        } else {
            carp 'No Unicode mapping table found. Gylphs will likely end up at wrong code points';

            for (my $i = 0; $i < $numglyph; $i++) {
                $chars->{$i} = $first + $i;
            }
        }
    } else {
        croak 'Bad magic';
    }
}


#@deprecated
sub import_hex {
    my ($self, $in, %opts) = @_;
    my $cur = scalar(@{$self->{glyphs}});
    my $chars = $self->{chars};
    my $height;
    my $wb;

    if (!ref $in) {
        my $gz = $in =~ /\.gz$/;
        my $fh;

        open($fh, '<', $in) or croak $!;
        $fh->binmode;
        $fh->binmode('gzip') if $gz;
        $in = $fh;
    }

    $self->bits(1);
    $self->height(16);

    {
        my $w  = $self->width;
        $wb = int($w/8) + (($w % 8) ? 1 : 0);
    }
    $height = $self->height;

    while (defined(my $line = <$in>)) {
        my ($cp, $pixel) = $line =~ /^([0-9A-F]{4,}):([0-9A-F]+)$/ or next;
        my $pixel_count;

        $cp = hex($cp);
        $pixel = pack('H*', $pixel);

        $pixel_count = length($pixel) / $height;

        if ($pixel_count == $wb) {
            # no-op
        } elsif ($pixel_count == 1 && $wb == 2) {
            # We need to fill the right side with zeros.
            $pixel = pack('v*', unpack('C*', $pixel));
        } else {
            next; # we cannot match this.
        }

        push(@{$self->{glyphs}}, ~. $pixel);
        $chars->{$cp} = $cur++;
    }
}

sub _import_ttf {
    require Font::FreeType;
    Font::FreeType->import(qw(FT_RENDER_MODE_MONO));
    require Image::Magick;

    my ($self, $in, %opts) = @_;
    my $face = Font::FreeType->new->face($in);
    my $height = $self->height;
    my $width = $self->width;
    my $baseline = $self->{baseline};
    my %flat_namedinfos;

    croak 'Stray options passed' if scalar keys %opts;

    $face->set_char_size($width, $height, 120, 72);

    $baseline //= int($height*$face->ascender/$face->height); # no better idea...

    {
        my $info = $face->namedinfos;
        foreach my $info (@{$info//[]}) {
            my $name_id = $info->name_id;
            my $platform_id = $info->platform_id;
            my $language_id = $info->language_id;

            if (($platform_id == 1 && $language_id == 0) || ($platform_id == 3 && $language_id == 0x0409)) {
                my $encoding = $_ttf_encodings{$info->platform_id}{$info->encoding_id} // next;
                my $value = Encode::decode($encoding, $info->string);
                $flat_namedinfos{$name_id} //= $value;
                $flat_namedinfos{$name_id} = [] if $flat_namedinfos{$name_id} ne $value;
            }
        }
    }

    $self->_set_value(baseline => $baseline);
    $self->_set_value(slant => $face->is_italic ? 'italic' : 'roman');
    $self->_set_value(weight => $face->is_bold ? 'bold' : 'normal');
    $self->_set_value(reverse_slant => 0);
    $self->_set_value(font_name => $face->family_name);

    if (defined($flat_namedinfos{5}) && !ref($flat_namedinfos{5})) {
        my $v = $flat_namedinfos{5};
        my ($version_major, $version_minor);

        if ($v =~ /^(?:MS core font:\s*)?[Vv]([0-9]+)\.([0-9]+)\s*\z/) {
            ($version_major, $version_minor) = (int($1), int($2));
        } elsif ($v =~ /^Version\s+([0-9]+)\.([0-9]+)(?:\s*;\s*[12][0-9]{3}-[01][0-9]-[0-3][0-9])?\s*\z/) {
            ($version_major, $version_minor) = (int($1), int($2));
        }

        if (defined $version_major) {
            $version_major =   0 if $version_major <   0;
            $version_major = 255 if $version_major > 255;
            $self->_set_value(version_major => $version_major);
        }
        if (defined $version_minor) {
            $version_minor =   0 if $version_minor <   0;
            $version_minor = 255 if $version_minor > 255;
            $self->_set_value(version_minor => $version_minor);
        }
        #warn sprintf('version: %s.%s', $version_major // '<undef>', $version_minor // '<undef>');
    }

    $face->foreach_char(sub {
            my $glyph = $_;
            my $code_point = $glyph->char_code;
            my ($bitmap, $left, $top) = $glyph->bitmap_magick(__PACKAGE__->FT_RENDER_MODE_MONO);
            my $p; # = Image::Magick->new;
            my $dy = $baseline - $top;
            my $error = 0;
            my $ok;

            $dy = 0 if $dy < 0;

            while ($error < 1) {
                $p = Image::Magick->new;
                $p->Set(size => sprintf('%ux%u', $width, $height));
                $p->Read('canvas:black');
                unless ($p->CopyPixels(image => $bitmap, x => 0, y => 0, dx => ($left > 0 ? $left : 0), dy => $dy)) {
                    $ok = 1;
                    last;
                }
                $error++;
                #warn sprintf('error: %u, codepoint: U+%04X', $error, $code_point);
                $left = 0;
                $dy = 0;
            }

            return unless $ok;

            $p->NegateImage;

            $self->glyph_for($code_point => $self->_import_glyph_wbmp($p->ImageToBlob(magick => 'wbmp')));
        });
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

    {
        my $fullname = File::Spec->catfile($directory, 'font-attributes.txt');
        $self->import_attributes($fullname) if -f $fullname;
    }

    {
        my $fullname = File::Spec->catfile($directory, 'alias-map.txt');
        $self->import_alias_map($fullname) if -f $fullname;
    }

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


sub export_font {
    my ($self, $type, $out, %opts) = @_;

    croak 'Stray options passed' if scalar keys %opts;

    if (!ref $out) {
        my $gz = $out =~ /\.gz\z/;
        my $fh;

        open($fh, '>', $out) or croak $!;
        $fh->binmode;
        $fh->binmode('gzip') if $gz;
        $out = $fh;
    }

    if ($type eq 'sf') {
        return $self->write($out);
    } elsif ($type eq 'hex') {
        return $self->_export_hex($out);
    } else {
        croak 'Unknown type given: '.$type;
    }
}

sub _export_hex {
    my ($self, $out) = @_;
    my $width = $self->width;
    my $chars = $self->{chars};
    my $glyphs = $self->{glyphs};

    $self->bits(1);
    $self->height(16);

    if ($width & 0x7) {
        croak 'Unsupported font width for hex format: '.$width;
    }

    foreach my $codepoint (sort {$a <=> $b} keys %{$chars}) {
        $out->printf("%04X:%s\n", $codepoint, uc unpack('H*', ~. $glyphs->[$chars->{$codepoint}]));
    }
}


sub make_up_glyphs {
    my ($self) = @_;
    my $w  = $self->width;
    my $h  = $self->height;
    my $vmiddleline = eval {$self->get_attribute('vmiddleline')};
    my $hmiddleline = eval {$self->get_attribute('hmiddleline')};
    my $h8 = $h/8;
    my $w8 = $w/8;
    my $wb = int($w8) + (($w % 8) ? 1 : 0);

    $self->bits(1);

    # U+0020 SPACE
    $self->_make_up_glyphs_add_one(0x0020 => [map {chr(0xFF) x $wb} 1..$h]);
    # U+2588 FULL BLOCK
    $self->_make_up_glyphs_add_one(0x2588 => [map {chr(0x00) x $wb} 1..$h]);

    # U+2581 LOWER ONE EIGHTH BLOCK .. U+2587 LOWER SEVEN EIGHTHS BLOCK
    for (my $i = 1; $i < 8; $i++) {
        $self->_make_up_glyphs_add_one((0x2580 + $i) => [map {chr(($h - $_) < ($i*$h8) ? 0x00 : 0xFF) x $wb} 1..$h]);
    }

    # U+2594 UPPER ONE EIGHTH BLOCK
    $self->_make_up_glyphs_add_one(0x2594 => [map {chr(($h - $_) > (7*$h8) || $_ == 1 ? 0x00 : 0xFF) x $wb} 1..$h]);
    # U+2580 UPPER HALF BLOCK
    $self->_make_up_glyphs_add_one(0x2580 => [map {chr($_ > (4*$h8) ? 0xFF : 0x00) x $wb} 1..$h]);

    # Dear reader, have fun figuring out this!
    # The basic idea is that we generate a pattern that is 8 or 16 bit wide and use that for the blocks.
    # The pattern is created using bit shifts in units of 1/8ths.
    # We also ensure that at least a one pixel bar is present, even if we would shift it all out (e.g. 1/8ths of 4 pixels is still one pixel).
    if ($wb == 1) {
        my $pattern;

        # U+2589 LEFT SEVEN EIGHTHS BLOCK .. U+258F LEFT ONE EIGHTH BLOCK
        for (my $i = 7; $i > 0; $i--) {
            $pattern = chr((0xFF >> ($i*$w8)) & 0x7F);
            $self->_make_up_glyphs_add_one((0x258F - $i + 1) => [map {$pattern} 1..$h]);
        }

        # U+2590 RIGHT HALF BLOCK
        $pattern = chr((~(0xFF >> ($w/2))) & 0xFF);
        $self->_make_up_glyphs_add_one(0x2590 => [map {$pattern} 1..$h]);

        # U+2595 RIGHT ONE EIGHTH BLOCK
        $pattern = chr(((~(0xFF >> (8-$w8))) & (0xFE << (8 - $w)) & 0xFF));
        $self->_make_up_glyphs_add_one(0x2595 => [map {$pattern} 1..$h]);
    } elsif ($wb == 2) {
        my $pattern;

        # U+2589 LEFT SEVEN EIGHTHS BLOCK .. U+258F LEFT ONE EIGHTH BLOCK
        for (my $i = 7; $i > 0; $i--) {
            $pattern = pack('n', (0xFFFF >> ($i*$w8)) & 0x7FFF);
            $self->_make_up_glyphs_add_one((0x258F - $i + 1) => [map {$pattern} 1..$h]);
        }

        # U+2590 RIGHT HALF BLOCK
        $pattern = pack('n', (~(0xFFFF >> ($w/2))) & 0xFFFF);
        $self->_make_up_glyphs_add_one(0x2590 => [map {$pattern} 1..$h]);

        # U+2595 RIGHT ONE EIGHTH BLOCK
        $pattern = pack('n', ((~(0xFFFF >> (16-$w8))) & (0xFFFE << (16 - $w)) & 0xFFFF));
        $self->_make_up_glyphs_add_one(0x2595 => [map {$pattern} 1..$h]);
    }

    if (defined($vmiddleline) && defined($hmiddleline)) {
        my @init = map {0xFFFF} 1..$h;
        foreach my $key (keys %_drawing_single) {
            my @lines = @init;
            my $vbit = 0xFFFF ^ (0x8000 >> $vmiddleline);

            $lines[$hmiddleline] &= 0xFFFF >> $vmiddleline if $key =~ /l/;
            $lines[$hmiddleline] &= 0xFFFF << (16 - $vmiddleline) if $key =~ /r/;
            if ($key =~ /t/) {
                $lines[$_] &= $vbit foreach 0..$hmiddleline;
            }
            if ($key =~ /b/) {
                $lines[$_] &= $vbit foreach $hmiddleline..($h-1);
            }

            if ($wb == 1) {
                $self->_make_up_glyphs_add_one($_drawing_single{$key} => [map {pack('C', ($_ >> 8) & 0xFF)} @lines]);
            } elsif ($wb == 2) {
                $self->_make_up_glyphs_add_one($_drawing_single{$key} => [map {pack('n', $_)} @lines]);
            }
        }
    }
}

sub _make_up_glyphs_add_one {
    my ($self, $cp, $lines) = @_;
    my $w = $self->width;
    my $res = '';
    my $glyph;

    $w = int($w/8) + (($w % 8) ? 1 : 0);

    $self->height(scalar(@{$lines}));

    foreach my $line (@{$lines}) {
        if (ref $line) {
            $line = pack('C*', @{$line});
        }
        croak 'BUG!' unless length($line) == $w;
        $res .= $line;
    }

    push(@{$self->{glyphs}}, $res);

    $glyph = scalar(@{$self->{glyphs}}) - 1;

    $self->default_glyph_for($cp => $glyph);

    return $glyph;
}


sub analyse {
    my ($self) = @_;
    my $w  = $self->width;
    my $msb;
    my $lsb;
    my $empty;
    my $mask;

    if ($w <= 8) {
        $msb = 0x80;
        $empty = 0xFF;
    } elsif ($w <= 16) {
        $msb = 0x8000;
        $empty = 0xFFFF;
    } else {
        croak 'Unsupported glyph width';
    }
    $mask = $empty >> $w;
    $lsb = $msb >> ($w - 1);

    #warn sprintf('MSB: 0x%04X, LSB: 0x%04X', $msb, $lsb);

    {
        my $baseline;
        my $matches = 0;
        foreach my $char (qw(A B C D E F)) { # All those characters should sit on the baseline
            eval {
                my @lines = $self->_analyse_read_char(ord($char));

                for (my $i = scalar(@lines) - 1; $i >= 0; $i--) {
                    my $d = $lines[$i] | $mask;
                    next if $d == $empty;
                    if (defined $baseline) {
                        last if $baseline != $i;
                    } else {
                        $baseline = $i;
                    }
                    $matches++;
                    last;
                    #printf("U+%04X %2u 0x%04X empty: 0x%04X\n", ord($char), $i, $d, $empty);
                }
                #say '---';
            };
        }

        # We require at least 4 matches.
        if ($matches >= 4) {
            eval { $self->_set_value(baseline => $baseline); }
        }
        #warn sprintf('Baseline: %u, matches: %u', $baseline, $matches);
    }

    {
        my $vmiddleline;
        my $hmiddleline;
        my $vmatches = 0;
        my $hmatches = 0;

        # We try to find rows and columns with only one pixel set. They must be the first or last.
        foreach my $cp (0x2500, 0x2502, 0x250C, 0x2510, 0x2514, 0x2518, 0x253C) {
            eval {
                my @lines = $self->_analyse_read_char($cp);
                my $vpixel;
                my $hpixel;

                mid:
                foreach my $l (@lines[0, -1]) {
                    my $d = ($l | $mask) ^ $empty; # only set pixels are now set in $d

                    for (my $i = 0; $i < $w; $i++) {
                        if ($d & ($msb >> $i)) {
                            if (defined($vpixel) && $vpixel != $i) {
                                $vpixel = undef;
                                last mid;
                            } else {
                                $vpixel = $i;
                            }
                        }
                    }
                }

                mid:
                for (my $i = scalar(@lines) - 1; $i >= 0; $i--) {
                    my $d = ($lines[$i] | $mask) ^ $empty; # only set pixels are now set in $d

                    #warn sprintf('%2u 0x%04X', $i, $d);
                    foreach my $k ($d & $msb, $d & $lsb) {
                        next unless $k;
                        if (defined($hpixel) && $hpixel != $i) {
                            $hpixel = undef;
                            last mid;
                        } else {
                            $hpixel = $i;
                        }
                    }
                }


                if (defined $vpixel) {
                    $vpixel = $vpixel;
                    if (defined $vmiddleline) {
                        $vmatches++ if $vmiddleline == $vpixel;
                    } else {
                        $vmiddleline = $vpixel;
                        $vmatches++;
                    }
                }
                if (defined $hpixel) {
                    if (defined $hmiddleline) {
                        $hmatches++ if $hmiddleline == $hpixel;
                    } else {
                        $hmiddleline = $hpixel;
                        $hmatches++;
                    }
                }

                #printf("U+%04X %2u 0x%04X empty: 0x%04X, vpixel: %s\n", $cp, 0, $lines[0], $empty, $vpixel // '<undef>');
            }
        }

        # We require at least 4 matches.
        if ($vmatches >= 4) {
            eval { $self->_set_value(vmiddleline => $vmiddleline); }
        }
        if ($hmatches >= 4) {
            eval { $self->_set_value(hmiddleline => $hmiddleline); }
        }
        #warn sprintf('vmiddleline: %u, matches: %u', $vmiddleline, $vmatches);
        #warn sprintf('hmiddleline: %u, matches: %u', $hmiddleline, $hmatches);
    }

    foreach my $cp (sort {$a <=> $b} keys %{$self->{chars}}) {
        my $attr = $self->{glyph_attr}[$self->{chars}{$cp}] // {};

        $attr->{resync} //= 1 if $cp >= 0x2500 && $cp <= 0x257F;

        if ($cp > 0x0020 && $cp < 0x007F && !$attr->{resync}) { # TODO: Improve check
            my @lines = $self->_analyse_read_char($cp);
            my $v = $lines[0];

            $v &= $_ foreach @lines;

            if (!defined($attr->{preskip})) {
                my $x = $v << (24 - $w);
                my $preskip = 0;

                for (; $preskip < 3; $preskip++, $x <<= 1) {
                    last if ($x & 0xC00000) != 0xC00000;
                }

                $attr->{preskip} = $preskip;
                #warn sprintf('U+%04X %02x -> preskip=%u', $cp, $v, $preskip);
            }

            if (!defined($attr->{postskip})) {
                my $x = $w & 7 ? $v >> (8 - ($w & 7)) : $v;
                my $k = $x;
                my $postskip = 0;

                for (; $postskip < 15; $postskip++, $x >>= 1) {
                    last if ($x & 0x03) != 0x03;
                }

                $postskip = 15 if $postskip > 15;
                $attr->{postskip} = $postskip;
                #warn sprintf('U+%04X %02x -> postskip=%u', $cp, $k, $postskip);
            }

            #warn sprintf('U+%04X %02x', $cp, $v);
        }

        if ($cp == 0x0020 && !defined($attr->{postskip})) {
            my $postskip = int($w / 4);
            $postskip = 15 if $postskip > 15;
            $attr->{postskip} = $postskip;
        }

        $self->{glyph_attr}[$self->{chars}{$cp}] = $attr if scalar keys %{$attr};
    }
}

sub _analyse_read_char {
    my ($self, $cp) = @_;
    my $glyph = $self->glyph_for($cp);
    my $w  = $self->width;
    my $p;

    $glyph = int($glyph) if defined $glyph;
    croak 'No valid glyph given' unless defined($glyph) && $glyph >= 0;
    $glyph = $self->{glyphs}[$glyph];
    croak 'No valid glyph given' unless defined($glyph);

    if ($self->bits != 1) {
        croak 'Unsupported glyph size';
    }

    if ($w <= 8) {
        return unpack('C*', $glyph);
    } elsif ($w <= 16) {
        return unpack('n*', $glyph);
    } else {
        croak 'Unsupported glyph width';
    }
}


#@returns SIRTX::Font::Renderer
sub renderer {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    require SIRTX::Font::Renderer;

    return SIRTX::Font::Renderer->new(font => $self);
}


#@deprecated
sub render {
    my ($self, @args) = @_;
    return $self->renderer->render(@args);
}

# TODO: This is not yet part of public API. make it public. reconsider how it should work before doing so.
sub list_info {
    my ($self, $list) = @_;
    my $chars = $_char_lists{$list};
    return undef unless defined $chars;
    return {
        name => $list,
        characters => scalar(@{$chars}),
    };
}

# ---- Private helpers ----

sub _render_font_flags {
    my ($self) = @_;
    my $slant = $self->get_attribute('slant');
    my $weight = $self->get_attribute('weight');
    my $res = 0;

    $res |= $self->has_all_codepoints_from('important') ? 1 << 5 : 0;
    $res |= $self->get_attribute('reverse_slant')       ? 0      : 1 << 4;

    if ($slant eq 'roman') {
        $res |= 3 << 2;
    } elsif ($slant eq 'italic') {
        $res |= 1 << 2;
    } elsif ($slant eq 'oblique') {
        $res |= 2 << 2;
    } else {
        $res |= 0;
    }

    if ($weight eq 'normal') {
        $res |= 3;
    } elsif ($weight eq 'bold') {
        $res |= 1;
    } elsif ($weight eq 'thin') {
        $res |= 2;
    } else {
        $res |= 0;
    }

    return 0xFF40 | $res;
}

sub _apply_font_flags {
    my ($self, $flags) = @_;

    # lower byte:
    if (($flags & 0xC0) == 0x40) {
        # Data in this byte
        my $slant  = $flags & 0x0C;
        my $weight = $flags & 0x03;
        $self->set_attribute(reverse_slant => ($flags & 0x10) == 0);

        if ($slant == 0x0C) {
            $self->set_attribute(slant => 'roman');
        } elsif ($slant == 0x04) {
            $self->set_attribute(slant => 'italic');
        } elsif ($slant == 0x08) {
            $self->set_attribute(slant => 'oblique');
        } else {
            $self->set_attribute(slant => 'other');
        }

        if ($weight == 0x03) {
            $self->set_attribute(weight => 'normal');
        } elsif ($weight == 0x01) {
            $self->set_attribute(weight => 'bold');
        } elsif ($weight == 0x02) {
            $self->set_attribute(weight => 'thin');
        } else {
            $self->set_attribute(weight => 'other');
        }
    } elsif (($flags & 0xC0) == 0xC0 || ($flags & 0xC0) == 0x00) {
        # no-op, no data
    } else {
        croak sprintf('Invalid or unsupported font flags: 0x%04X', $flags);
    }

    # upper byte:
    if (($flags & 0xC000) == 0xC000 || ($flags & 0xC000) == 0x0000) {
        # no-op, no data
    } else {
        croak sprintf('Invalid or unsupported font flags: 0x%04X', $flags);
    }
}

sub _render_early_hints {
    my ($self, $skips) = @_;

    $skips //= 0;

    return pack('nCCCCn', DATA_START_MARKER,
        $self->width, $self->height,
        $skips,
        HEADER_EARLY_HINTS,
        $self->_render_font_flags,
    );
}

sub _render_geometry_hints {
    my ($self) = @_;
    return pack('nCCCCn', DATA_START_MARKER,
        $self->get_attribute('hmiddleline'), $self->get_attribute('vmiddleline'),
        $self->get_attribute('baseline'),
        HEADER_GEOMETRY_HINTS,
        $self->_render_font_flags,
    );
}

sub _render_identity {
    my ($self) = @_;
    my $minor = $self->get_attribute('version_minor') << 2;
    my $version_type = $self->get_attribute('version_type');
    my $uuid = eval {$self->{util}->pack(uuid128 => $self->get_attribute('font_tag'))};
    my $extra = '';

    if ($version_type eq 'stable') {
        $minor |= 3;
    } elsif ($version_type eq 'rc') {
        $minor |= 2;
    } elsif ($version_type eq 'beta') {
        $minor |= 1;
    } elsif ($version_type eq 'devel') {
        $minor |= 0;
    } else {
        croak 'Invalid version type: '.$version_type;
    }

    if (defined $uuid) {
        $extra = $uuid;
    }

    if (defined(my $name = eval {$self->get_attribute('font_name')})) {
        my $len;

        if (length($extra) != 16) {
            $extra = chr(0) x 16;
        }

        $name = UTF_8->encode($name);
        $len = length($name);

        if ($len % 8) {
            $name .= chr(0);
            $len++;
            if ($len % 8) {
                $name .= chr(0xFF) x (8 - ($len % 8));
            }
        }

        $extra .= $name;
    }

    # TODO: Add support to write name of font

    return pack('nCCCCn', DATA_START_MARKER,
        $self->get_attribute('version_major'),
        $minor,
        length($extra) / 8,
        HEADER_IDENTIFIER,
        $self->get_attribute('last_modification')->datecode,
    ).$extra;
}

sub _render_displayinfo {
    my ($self) = @_;
    my $icontext = eval {$self->get_attribute('icontext')};
    my $displaycolour = eval {$self->get_attribute('displaycolour')};
    my $displaycolour_412;
    my $displaycolour_rgb;
    my $icontext_16;
    my $extra = '';

    return unless defined($icontext) || defined($displaycolour);

    $icontext //= 0xFFFFFFFF;

    if (defined $displaycolour) {
        require Data::Identifier::Wellknown;
        Data::Identifier::Wellknown->import(':all');
    }
    $displaycolour_412   = defined($displaycolour) ? eval {$self->{util}->pack('4+12', $displaycolour)} : undef;
    $displaycolour_412 //= pack('n', 0);
    $icontext_16 = $icontext >= 0xFFFF ? 0xFFFF : $icontext;

    if (defined($displaycolour) && eval { $displaycolour->generator->eq('55febcc4-6655-4397-ae3d-2353b5856b34') } ) {
        eval {
            $displaycolour_rgb = pack('xH6', substr($displaycolour->request, 1));
        };
    }

    if ((defined($icontext) && $icontext >= 0xFFFD) || defined($displaycolour_rgb)) {
        $extra .= defined($icontext) ? pack('N', $icontext & 0xFFFFFF) : chr(255) x 4;
        $extra .= defined($displaycolour_rgb) ? $displaycolour_rgb : chr(255) x 4;
    }

    return pack('nnCCa2', DATA_START_MARKER,
        $icontext_16,
        length($extra) / 8,
        HEADER_DISPLAYINFO | ($extra ne '' ? DATA_BIT : 0),
        $displaycolour_412,
    ).$extra;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::Font - module for working with SIRTX font files

=head1 VERSION

version v0.08

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

=head1 ATTRIBUTES

The following font attributes are currently supported.
See L</set_attribute> for details.
Unless otherwise given all values are counted from top-left, starting with 0.

=over

=item C<width>, C<height>, C<bits>

Integer values, see L</width>, L</height>, and L</bits> for details.

=item C<baseline>

The baseline of the font. This is the lowest scanline most capital latin letters sit on.

=item C<vmiddleline>

The vertical middle line is the column that represents the visual middle of the font.
It is used mostly by box drawing characters when a vertical line is required.

=item C<hmiddleline>

The horizontal middle line is the scanline that represents the visual middle of the font.
It is used mostly by box drawing characters when a horizontal line is required.

=item C<version_major>

The major part of the version.
The value is in range 0 to 255.
The value 255 has the special meaning of being later than any other version.
This means that if the font is in version greater than 254 the value is always 255.

=item C<version_minor>

The minor part of the version.
The value is in range 0 to 63.
The value of 63 has the special meaning of being later than any other version.
This means that if the font has more minor versions than 63, all versions 63 or later are stored as 63.

=item C<version_type>

The version type.
One of C<devel> (development), C<beta> (beta version), C<rc> (release candidate), or C<stable>.
The type is applied in a I<towards> way:
e.g. version C<2.5-beta> is lower than C<2.5-stable>, but greater than C<2.4-stable>.

=item C<weight>

The font weight defines the "boldness" of the font.
One of C<normal>, C<bold>, C<thin>, or C<other>.

=item C<slant>

The slant defines how upright a font is.
One of C<roman> (upright), C<italic> (leaning), C<oblique> (sheared), or C<other>.

=item C<reverse_slant>

Boolean indicating if the slant is reverse (towards left, C<true>) or normal (towards right, C<false>).
Fonts with a C<roman> slant are always non-reverse-slant.

=item C<last_modification>

The timestamp of the last modification.
This value is updated internally and should only be read.

As of v0.07 this is a L<SIRTX::Datecode>.

=item C<font_tag>

The permanent tag for this font.
This tag stays the same with all versions of this font, but is updated for variants (e.g. forked projects) of the same font.
It can be used (together with the version or alone) to identify the font uniquely and globally.

As of v0.07 this is a L<Data::Identifier> which must allow for L<Data::Identifier/uuid>.

=item C<font_name>

The name of the font.
This string is mostly used to present to the user.
It should not be used to identify the font. See L</font_tag> for that.

The font name can contain any unicode characters.
However the following recommendations should be considered:

=over

=item *

The font should contain all characters needed to render it's own name.

=item *

Any control characters, overly complicated characters, or composite characters should be avoided.

=item *

Spaces should be preferred over dashes or underscores. This is a name, not an identifier.

=item *

The font name should be kept short but precise. It should not contain a the name of the foundry, artist, or creator.

=back

=item C<icontext>

(experimental since v0.07)

A codepoint that is used as icontext.
This is commonly unset.
It can be any code point.
However it is recommended that the font includes given character.

=item C<displaycolour>

(experimental since v0.07)

A colour to be used to represent the font.
This can be used to aid the user finding the corresponding font faster.

As of v0.07 this is a L<Data::Identifier>.
The value might or might not require to have a assigned SNI, SID, or RGB value.

It might be useful to import L<Data::Identifier::Wellknown> with C<:all> so SNI and SID values are known.

=back

=head1 METHODS

=head2 new

    my SIRTX::Font $font = SIRTX::Font->new;

Creates a new font object. No parameters are supported.

=head2 gc

    $font->gc;

(experimental since v0.01)

Takes the trash out. This will remove unused glyphs and deduplicate glyphs that are still in use.

B<Note:>
After a call to this all glyph numbers become invalid.

B<Note:>
This function tries to merge glyph attributes. However it may not do this correctly.
Problems can be avoided by calling this method before adding glyph attributes.
For example by adding all glyphs, then calling this method, and then adding all glyph attributes.
It is also safe when attributes of merged glyphs are equal.

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

=head2 list_attributes

    my @attributes = $font->list_attributes;

(experimental since v0.06)

Lists known attribute keys.
The returned list may depend on the currently loaded font.
Keys may be returned for attributes that are currently unset.
Keys are returned for attributes that are currently set.

B<Note:>
This method will most likely be removed soon.

=head2 get_attribute

    my $value = $font->get_attribute($key);

(experimental since v0.06)

Returns an attribute value or dies if it is unset.

=head2 set_attribute

    $font->set_attribute($key => $value);

(experimental since v0.06)

Sets an attribute. Will die if the value does not validate.

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
To remove the glyph call L</gc> after this call.
Note that it will be faster to first remove all code points and then perform a single call to L</gc> if you want to remove multiple codepoints.

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
This will only remove the code points, not the glyphs as per L</remove_codepoint>. See there for details on how to also remove the glyphs.

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

(experimental since v0.02)

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

=head2 get_glyph_attribute

    my $value = $font->get_glyph_attribute($glyph, $key);

(experimental since v0.08)

Returns an attribute value for a glyph or dies if it is unset.

=head2 set_glyph_attribute

    $font->set_glyph_attribute($glyph, $key => $value);

(experimental since v0.08)

Sets an attribute of a glyph. Will die if the value does not validate.

See also notes about glyphs and garbage collection in L</gc>.

B<Note:>
As of v0.08 glyph attributes cannot be stored to any font file.
Future versions of this module will allow this.

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

(experimental since v0.04)

Imports an alias map from the given file.

The format is one alias group per line.
Each line is formatted into two sections.
The first section lists all the code points that are aliased to each other.
The second part (seperated by a C<-->) lists all the code points that
are only aliased to (that is they will share the glyph from the first part,
but the code points from the first part will not share glyph with the second part).

Each part is a list of codepoints in C<U+NNNN> format, seperated by space, comma or both.

This method will ignore if a mapped glyph does not exists alike L</default_glyph_for>.

=head2 import_attributes

    $font->import_attributes($filename);

(experimental since v0.07)

Imports an font attributes from the given file.

The format consist of simple key-value-pairs separated by a single C<=>, optionally with spaces.

Possible keys and values are the same as for L</set_attribute>.

=head2 import_font

    $font->import_font($type => $filename [, %opts] );

(since v0.08)

This allows to import fonts in different formats.

Currently no options are supported.

The following types are currently supported:

=over

=item C<auto>

(experimental since v0.08)

This tries to auto-detect the type of the font.
The autodetection logic is still very unreliable as of v0.08.
So it is best to avoid this feature when the type is actually known.

=item C<hex>

Imports Roman's .hex format. This supports both 8 and 16 pixel width glyphs.
If the font is set to pixel width 8 pixel glyphs are extended with space to match 16 pixel.

B<Note:>
The font must be set to 8 or 16 pixel width before this function is called.
See L</width> for details.

=item C<psf>

Imports a PC Screen Font (PSF) file into the font.

Supports PSF1, and PSF2 files at this point.

B<Note:>
Files without a Unicode table might import incorrectly.

=item C<sf>

Imports a SIRTX Font. This is doing the same as L</read> (but accepts a filename).

=back

=head2 import_psf

    $font->import_psf($filename);

(experimental since v0.06, deprecated since v0.08, will be removed in v0.10, may warn)

B<Note:>
This method is deprecated and will be removed soon. Please update all usage to L</import_font>.

Imports a PC Screen Font (PSF) file into the font.

Supports PSF1, and PSF2 files at this point.

Note that files without a Unicode table might import incorrectly.

=head2 import_hex

    $font->import_hex($filename);

(since v0.07, deprecated since v0.08, will be removed in v0.10, may warn)

B<Note:>
This method is deprecated and will be removed soon. Please update all usage to L</import_font>.

Imports Roman's .hex format. This supports both 8 and 16 pixel width glyphs.
If the font is set to pixel width 8 pixel glyphs are extended with space to match 16 pixel.

B<Note:>
The font must be set to 8 or 16 pixel width before this function is called.
See L</width> for details.

=head2 import_directory

    $font->import_directory($filename [, %opts ]);

(experimental since v0.02)

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

(experimental since v0.01)

Exports a single glyph as a image object.

=head2 export_alias_map

    $font->export_alias_map($filename);

(experimental since v0.04)

Exports the map of all aliases found in the font.
This is the inverse of L</import_alias_map>.

B<Note:>
This method cannot know which code points are aliases one way and which are aliased both ways.
This information is not included in the binary format.
Therefore this method exports all aliases as both way aliases.
This is the same behaviour as known from hardlinks.

=head2 export_font

    $font->export_font($type => $filename [, %opts] );

(since v0.08)

This allows to export fonts in different formats.

Currently no options are supported.

The following types are currently supported:

=over

=item C<hex>

Exports Roman's .hex format. This supports both 8 and 16 pixel width glyphs.

=item C<sf>

Exports a SIRTX Font. This is doing the same as L</write> (but accepts a filename).

=back

=head2 make_up_glyphs

    $font->make_up_glyphs;

(experimental since v0.06)

Makes up glyphs for the font.
This will create glyphs that can be easily calculated, such as the space character (all blank).

The exact list of characters that can be made up depend on the version of this module and the available font data.
Therefore this should be called late in processing a font, so that as much data is available to the algorithm as possible.

L</add_default_aliases> should be called after this step if called at all.
L</gc> should be called after this step, as this step might generate glyphs that are in fact unused.

B<Note:>
This step can not easily be undone. It should be used with care on font files that a meant to be edited.

B<Note:>
Code points are added as per L</default_glyph_for>.

=head2 analyse

    $font->analyse;

(experimental since v0.06)

Analyses the font to find additional attributes automatically.

This can be useful specifically when importing pre-existing fonts.

However the result should be manually checked as the values might not reflect reality.

=head2 renderer

    my SIRTX::Font::Renderer $renderer = $font->renderer;

(since v0.08)

Returns a new renderer object which can be used to render text using this font.

=head2 render

    my Image::Magick $image = $font->render($string);
    # e.g.:
    my Image::Magick $image = $font->render("Hello World!");
    $image->Transparent(color => 'white'); # transparent background
    $image->Write('hello.png');

(experimental since v0.03, deprecated since v0.08, will be removed in v0.10, may warn)

B<Note:>
This method is now deprecated.
Please use L<SIRTX::Font::Renderer>.
See also L</renderer>.

Renders a text using the loaded font.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
