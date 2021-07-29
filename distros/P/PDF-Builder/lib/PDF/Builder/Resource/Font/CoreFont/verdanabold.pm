package PDF::Builder::Resource::Font::CoreFont::verdanabold;

use strict;
use warnings;

our $VERSION = '3.023'; # VERSION
our $LAST_UPDATE = '3.018'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::Font::CoreFont::verdanabold - font-specific information for bold weight Verdana font
(I<not> standard PDF core)

=cut

sub data { return {
    'fontname' => 'Verdana,Bold',
    'type' => 'TrueType',
    'apiname' => 'VeBo',
    'ascender' => '1005',
    'capheight' => '727',
    'descender' => '-209',
    'isfixedpitch' => '0',
    'issymbol' => '0',
    'italicangle' => '0',
    'underlineposition' => '-139',
    'underlinethickness' => '211',
    'xheight' => '548',
    'firstchar' => '32',
    'lastchar' => '255',
    'flags' => '262176',
    'char' => [ # DEF. ENCODING GLYPH TABLE
        '.notdef',                               # C+0x00 # U+0x0000
        '.notdef',                               # C+0x01 # U+0x0000
        '.notdef',                               # C+0x02 # U+0x0000
        '.notdef',                               # C+0x03 # U+0x0000
        '.notdef',                               # C+0x04 # U+0x0000
        '.notdef',                               # C+0x05 # U+0x0000
        '.notdef',                               # C+0x06 # U+0x0000
        '.notdef',                               # C+0x07 # U+0x0000
        '.notdef',                               # C+0x08 # U+0x0000
        '.notdef',                               # C+0x09 # U+0x0000
        '.notdef',                               # C+0x0A # U+0x0000
        '.notdef',                               # C+0x0B # U+0x0000
        '.notdef',                               # C+0x0C # U+0x0000
        '.notdef',                               # C+0x0D # U+0x0000
        '.notdef',                               # C+0x0E # U+0x0000
        '.notdef',                               # C+0x0F # U+0x0000
        '.notdef',                               # C+0x10 # U+0x0000
        '.notdef',                               # C+0x11 # U+0x0000
        '.notdef',                               # C+0x12 # U+0x0000
        '.notdef',                               # C+0x13 # U+0x0000
        '.notdef',                               # C+0x14 # U+0x0000
        '.notdef',                               # C+0x15 # U+0x0000
        '.notdef',                               # C+0x16 # U+0x0000
        '.notdef',                               # C+0x17 # U+0x0000
        '.notdef',                               # C+0x18 # U+0x0000
        '.notdef',                               # C+0x19 # U+0x0000
        '.notdef',                               # C+0x1A # U+0x0000
        '.notdef',                               # C+0x1B # U+0x0000
        '.notdef',                               # C+0x1C # U+0x0000
        '.notdef',                               # C+0x1D # U+0x0000
        '.notdef',                               # C+0x1E # U+0x0000
        '.notdef',                               # C+0x1F # U+0x0000
        'space',                                 # C+0x20 # U+0x0020
        'exclam',                                # C+0x21 # U+0x0021
        'quotedbl',                              # C+0x22 # U+0x0022
        'numbersign',                            # C+0x23 # U+0x0023
        'dollar',                                # C+0x24 # U+0x0024
        'percent',                               # C+0x25 # U+0x0025
        'ampersand',                             # C+0x26 # U+0x0026
        'quotesingle',                           # C+0x27 # U+0x0027
        'parenleft',                             # C+0x28 # U+0x0028
        'parenright',                            # C+0x29 # U+0x0029
        'asterisk',                              # C+0x2A # U+0x002A
        'plus',                                  # C+0x2B # U+0x002B
        'comma',                                 # C+0x2C # U+0x002C
        'hyphen',                                # C+0x2D # U+0x002D
        'period',                                # C+0x2E # U+0x002E
        'slash',                                 # C+0x2F # U+0x002F
        'zero',                                  # C+0x30 # U+0x0030
        'one',                                   # C+0x31 # U+0x0031
        'two',                                   # C+0x32 # U+0x0032
        'three',                                 # C+0x33 # U+0x0033
        'four',                                  # C+0x34 # U+0x0034
        'five',                                  # C+0x35 # U+0x0035
        'six',                                   # C+0x36 # U+0x0036
        'seven',                                 # C+0x37 # U+0x0037
        'eight',                                 # C+0x38 # U+0x0038
        'nine',                                  # C+0x39 # U+0x0039
        'colon',                                 # C+0x3A # U+0x003A
        'semicolon',                             # C+0x3B # U+0x003B
        'less',                                  # C+0x3C # U+0x003C
        'equal',                                 # C+0x3D # U+0x003D
        'greater',                               # C+0x3E # U+0x003E
        'question',                              # C+0x3F # U+0x003F
        'at',                                    # C+0x40 # U+0x0040
        'A',                                     # C+0x41 # U+0x0041
        'B',                                     # C+0x42 # U+0x0042
        'C',                                     # C+0x43 # U+0x0043
        'D',                                     # C+0x44 # U+0x0044
        'E',                                     # C+0x45 # U+0x0045
        'F',                                     # C+0x46 # U+0x0046
        'G',                                     # C+0x47 # U+0x0047
        'H',                                     # C+0x48 # U+0x0048
        'I',                                     # C+0x49 # U+0x0049
        'J',                                     # C+0x4A # U+0x004A
        'K',                                     # C+0x4B # U+0x004B
        'L',                                     # C+0x4C # U+0x004C
        'M',                                     # C+0x4D # U+0x004D
        'N',                                     # C+0x4E # U+0x004E
        'O',                                     # C+0x4F # U+0x004F
        'P',                                     # C+0x50 # U+0x0050
        'Q',                                     # C+0x51 # U+0x0051
        'R',                                     # C+0x52 # U+0x0052
        'S',                                     # C+0x53 # U+0x0053
        'T',                                     # C+0x54 # U+0x0054
        'U',                                     # C+0x55 # U+0x0055
        'V',                                     # C+0x56 # U+0x0056
        'W',                                     # C+0x57 # U+0x0057
        'X',                                     # C+0x58 # U+0x0058
        'Y',                                     # C+0x59 # U+0x0059
        'Z',                                     # C+0x5A # U+0x005A
        'bracketleft',                           # C+0x5B # U+0x005B
        'backslash',                             # C+0x5C # U+0x005C
        'bracketright',                          # C+0x5D # U+0x005D
        'asciicircum',                           # C+0x5E # U+0x005E
        'underscore',                            # C+0x5F # U+0x005F
        'grave',                                 # C+0x60 # U+0x0060
        'a',                                     # C+0x61 # U+0x0061
        'b',                                     # C+0x62 # U+0x0062
        'c',                                     # C+0x63 # U+0x0063
        'd',                                     # C+0x64 # U+0x0064
        'e',                                     # C+0x65 # U+0x0065
        'f',                                     # C+0x66 # U+0x0066
        'g',                                     # C+0x67 # U+0x0067
        'h',                                     # C+0x68 # U+0x0068
        'i',                                     # C+0x69 # U+0x0069
        'j',                                     # C+0x6A # U+0x006A
        'k',                                     # C+0x6B # U+0x006B
        'l',                                     # C+0x6C # U+0x006C
        'm',                                     # C+0x6D # U+0x006D
        'n',                                     # C+0x6E # U+0x006E
        'o',                                     # C+0x6F # U+0x006F
        'p',                                     # C+0x70 # U+0x0070
        'q',                                     # C+0x71 # U+0x0071
        'r',                                     # C+0x72 # U+0x0072
        's',                                     # C+0x73 # U+0x0073
        't',                                     # C+0x74 # U+0x0074
        'u',                                     # C+0x75 # U+0x0075
        'v',                                     # C+0x76 # U+0x0076
        'w',                                     # C+0x77 # U+0x0077
        'x',                                     # C+0x78 # U+0x0078
        'y',                                     # C+0x79 # U+0x0079
        'z',                                     # C+0x7A # U+0x007A
        'braceleft',                             # C+0x7B # U+0x007B
        'bar',                                   # C+0x7C # U+0x007C
        'braceright',                            # C+0x7D # U+0x007D
        'asciitilde',                            # C+0x7E # U+0x007E
        'bullet',                                # C+0x7F # U+0x2022
        'Euro',                                  # C+0x80 # U+0x20AC
        'bullet',                                # C+0x81 # U+0x2022
        'quotesinglbase',                        # C+0x82 # U+0x201A
        'florin',                                # C+0x83 # U+0x0192
        'quotedblbase',                          # C+0x84 # U+0x201E
        'ellipsis',                              # C+0x85 # U+0x2026
        'dagger',                                # C+0x86 # U+0x2020
        'daggerdbl',                             # C+0x87 # U+0x2021
        'circumflex',                            # C+0x88 # U+0x02C6
        'perthousand',                           # C+0x89 # U+0x2030
        'Scaron',                                # C+0x8A # U+0x0160
        'guilsinglleft',                         # C+0x8B # U+0x2039
        'OE',                                    # C+0x8C # U+0x0152
        'bullet',                                # C+0x8D # U+0x2022
        'Zcaron',                                # C+0x8E # U+0x017D
        'bullet',                                # C+0x8F # U+0x2022
        'bullet',                                # C+0x90 # U+0x2022
        'quoteleft',                             # C+0x91 # U+0x2018
        'quoteright',                            # C+0x92 # U+0x2019
        'quotedblleft',                          # C+0x93 # U+0x201C
        'quotedblright',                         # C+0x94 # U+0x201D
        'bullet',                                # C+0x95 # U+0x2022
        'endash',                                # C+0x96 # U+0x2013
        'emdash',                                # C+0x97 # U+0x2014
        'tilde',                                 # C+0x98 # U+0x02DC
        'trademark',                             # C+0x99 # U+0x2122
        'scaron',                                # C+0x9A # U+0x0161
        'guilsinglright',                        # C+0x9B # U+0x203A
        'oe',                                    # C+0x9C # U+0x0153
        'bullet',                                # C+0x9D # U+0x2022
        'zcaron',                                # C+0x9E # U+0x017E
        'Ydieresis',                             # C+0x9F # U+0x0178
        'space',                                 # C+0xA0 # U+0x0020
        'exclamdown',                            # C+0xA1 # U+0x00A1
        'cent',                                  # C+0xA2 # U+0x00A2
        'sterling',                              # C+0xA3 # U+0x00A3
        'currency',                              # C+0xA4 # U+0x00A4
        'yen',                                   # C+0xA5 # U+0x00A5
        'brokenbar',                             # C+0xA6 # U+0x00A6
        'section',                               # C+0xA7 # U+0x00A7
        'dieresis',                              # C+0xA8 # U+0x00A8
        'copyright',                             # C+0xA9 # U+0x00A9
        'ordfeminine',                           # C+0xAA # U+0x00AA
        'guillemotleft',                         # C+0xAB # U+0x00AB
        'logicalnot',                            # C+0xAC # U+0x00AC
        'hyphen',                                # C+0xAD # U+0x002D
        'registered',                            # C+0xAE # U+0x00AE
        'macron',                                # C+0xAF # U+0x00AF
        'degree',                                # C+0xB0 # U+0x00B0
        'plusminus',                             # C+0xB1 # U+0x00B1
        'twosuperior',                           # C+0xB2 # U+0x00B2
        'threesuperior',                         # C+0xB3 # U+0x00B3
        'acute',                                 # C+0xB4 # U+0x00B4
        'mu',                                    # C+0xB5 # U+0x00B5
        'paragraph',                             # C+0xB6 # U+0x00B6
        'periodcentered',                        # C+0xB7 # U+0x00B7
        'cedilla',                               # C+0xB8 # U+0x00B8
        'onesuperior',                           # C+0xB9 # U+0x00B9
        'ordmasculine',                          # C+0xBA # U+0x00BA
        'guillemotright',                        # C+0xBB # U+0x00BB
        'onequarter',                            # C+0xBC # U+0x00BC
        'onehalf',                               # C+0xBD # U+0x00BD
        'threequarters',                         # C+0xBE # U+0x00BE
        'questiondown',                          # C+0xBF # U+0x00BF
        'Agrave',                                # C+0xC0 # U+0x00C0
        'Aacute',                                # C+0xC1 # U+0x00C1
        'Acircumflex',                           # C+0xC2 # U+0x00C2
        'Atilde',                                # C+0xC3 # U+0x00C3
        'Adieresis',                             # C+0xC4 # U+0x00C4
        'Aring',                                 # C+0xC5 # U+0x00C5
        'AE',                                    # C+0xC6 # U+0x00C6
        'Ccedilla',                              # C+0xC7 # U+0x00C7
        'Egrave',                                # C+0xC8 # U+0x00C8
        'Eacute',                                # C+0xC9 # U+0x00C9
        'Ecircumflex',                           # C+0xCA # U+0x00CA
        'Edieresis',                             # C+0xCB # U+0x00CB
        'Igrave',                                # C+0xCC # U+0x00CC
        'Iacute',                                # C+0xCD # U+0x00CD
        'Icircumflex',                           # C+0xCE # U+0x00CE
        'Idieresis',                             # C+0xCF # U+0x00CF
        'Eth',                                   # C+0xD0 # U+0x00D0
        'Ntilde',                                # C+0xD1 # U+0x00D1
        'Ograve',                                # C+0xD2 # U+0x00D2
        'Oacute',                                # C+0xD3 # U+0x00D3
        'Ocircumflex',                           # C+0xD4 # U+0x00D4
        'Otilde',                                # C+0xD5 # U+0x00D5
        'Odieresis',                             # C+0xD6 # U+0x00D6
        'multiply',                              # C+0xD7 # U+0x00D7
        'Oslash',                                # C+0xD8 # U+0x00D8
        'Ugrave',                                # C+0xD9 # U+0x00D9
        'Uacute',                                # C+0xDA # U+0x00DA
        'Ucircumflex',                           # C+0xDB # U+0x00DB
        'Udieresis',                             # C+0xDC # U+0x00DC
        'Yacute',                                # C+0xDD # U+0x00DD
        'Thorn',                                 # C+0xDE # U+0x00DE
        'germandbls',                            # C+0xDF # U+0x00DF
        'agrave',                                # C+0xE0 # U+0x00E0
        'aacute',                                # C+0xE1 # U+0x00E1
        'acircumflex',                           # C+0xE2 # U+0x00E2
        'atilde',                                # C+0xE3 # U+0x00E3
        'adieresis',                             # C+0xE4 # U+0x00E4
        'aring',                                 # C+0xE5 # U+0x00E5
        'ae',                                    # C+0xE6 # U+0x00E6
        'ccedilla',                              # C+0xE7 # U+0x00E7
        'egrave',                                # C+0xE8 # U+0x00E8
        'eacute',                                # C+0xE9 # U+0x00E9
        'ecircumflex',                           # C+0xEA # U+0x00EA
        'edieresis',                             # C+0xEB # U+0x00EB
        'igrave',                                # C+0xEC # U+0x00EC
        'iacute',                                # C+0xED # U+0x00ED
        'icircumflex',                           # C+0xEE # U+0x00EE
        'idieresis',                             # C+0xEF # U+0x00EF
        'eth',                                   # C+0xF0 # U+0x00F0
        'ntilde',                                # C+0xF1 # U+0x00F1
        'ograve',                                # C+0xF2 # U+0x00F2
        'oacute',                                # C+0xF3 # U+0x00F3
        'ocircumflex',                           # C+0xF4 # U+0x00F4
        'otilde',                                # C+0xF5 # U+0x00F5
        'odieresis',                             # C+0xF6 # U+0x00F6
        'divide',                                # C+0xF7 # U+0x00F7
        'oslash',                                # C+0xF8 # U+0x00F8
        'ugrave',                                # C+0xF9 # U+0x00F9
        'uacute',                                # C+0xFA # U+0x00FA
        'ucircumflex',                           # C+0xFB # U+0x00FB
        'udieresis',                             # C+0xFC # U+0x00FC
        'yacute',                                # C+0xFD # U+0x00FD
        'thorn',                                 # C+0xFE # U+0x00FE
        'ydieresis',                             # C+0xFF # U+0x00FF
    ], # DEF. ENCODING GLYPH TABLE
    'fontbbox' => [ -73, -207, 1707, 1000 ],
# source: \Windows\Fonts\verdanab.ttf
# font underline position = -139
# CIDs 0 .. 1396 to be output
# fontbbox = (-549 -303 1707 1071)
    'wx' => { # HORIZ. WIDTH TABLE
        'A'       => 776,
        'AE'       => 1093,
        'AEacute'       => 1093,
        'Aacute'       => 776,
        'Abreve'       => 776,
        'Abreveacute'       => 776,
        'Abrevedotbelow'       => 776,
        'Abrevegrave'       => 776,
        'Abrevehookabove'       => 776,
        'Abrevetilde'       => 776,
        'Acircumflex'       => 776,
        'Acircumflexacute'       => 776,
        'Acircumflexdotbelow'       => 776,
        'Acircumflexgrave'       => 776,
        'Acircumflexhookabove'       => 776,
        'Acircumflextilde'       => 776,
        'Adieresis'       => 776,
        'Adotbelow'       => 776,
        'Agrave'       => 776,
        'Ahookabove'       => 776,
        'Alpha'       => 776,
        'Alphatonos'       => 797,
        'Amacron'       => 776,
        'Aogonek'       => 776,
        'Aring'       => 776,
        'Aringacute'       => 776,
        'Atilde'       => 776,
        'Aybarmenian'       => 844,
        'B'       => 761,
        'Benarmenian'       => 799,
        'Beta'       => 761,
        'C'       => 723,
        'Caarmenian'       => 822,
        'Cacute'       => 723,
        'Ccaron'       => 723,
        'Ccedilla'       => 723,
        'Ccircumflex'       => 723,
        'Cdotaccent'       => 723,
        'Chaarmenian'       => 729,
        'Cheabkhasiancyrillic'       => 1014,
        'Chedescenderabkhasiancyrillic'       => 1014,
        'Cheharmenian'       => 795,
        'Cheverticalstrokecyrillic'       => 787,
        'Chi'       => 763,
        'Coarmenian'       => 765,
        'D'       => 830,
        'Daarmenian'       => 805,
        'Dcaron'       => 830,
        'Dcroat'       => 830,
        'Delta'       => 805,
        'E'       => 683,
        'Eacute'       => 683,
        'Ebreve'       => 683,
        'Ecaron'       => 683,
        'Echarmenian'       => 807,
        'Ecircumflex'       => 683,
        'Ecircumflexacute'       => 683,
        'Ecircumflexdotbelow'       => 683,
        'Ecircumflexgrave'       => 683,
        'Ecircumflexhookabove'       => 683,
        'Ecircumflextilde'       => 683,
        'Edieresis'       => 683,
        'Edotaccent'       => 683,
        'Edotbelow'       => 683,
        'Egrave'       => 683,
        'Eharmenian'       => 717,
        'Ehookabove'       => 683,
        'Emacron'       => 683,
        'Endescendercyrillic'       => 837,
        'Eng'       => 846,
        'Eogonek'       => 683,
        'Epsilon'       => 683,
        'Epsilontonos'       => 847,
        'Eta'       => 837,
        'Etarmenian'       => 807,
        'Etatonos'       => 1000,
        'Eth'       => 830,
        'Etilde'       => 683,
        'Euro'       => 710,
        'F'       => 650,
        'Feharmenian'       => 898,
        'G'       => 811,
        'Gamma'       => 637,
        'Gbreve'       => 811,
        'Gcircumflex'       => 811,
        'Gcommaaccent'       => 811,
        'Gdotaccent'       => 811,
        'Ghadarmenian'       => 817,
        'Ghestrokecyrillic'       => 637,
        'Gimarmenian'       => 827,
        'H'       => 837,
        'H18533'       => 604,
        'H18543'       => 354,
        'H18551'       => 354,
        'H22073'       => 604,
        'Haabkhasiancyrillic'       => 871,
        'Hadescendercyrillic'       => 763,
        'Hbar'       => 837,
        'Hcircumflex'       => 837,
        'Hoarmenian'       => 666,
        'I'       => 545,
        'IJ'       => 1007,
        'Iacute'       => 545,
        'Ibreve'       => 545,
        'Icircumflex'       => 545,
        'Idieresis'       => 545,
        'Idotaccent'       => 545,
        'Idotbelow'       => 545,
        'Igrave'       => 545,
        'Ihookabove'       => 545,
        'Imacron'       => 545,
        'Iniarmenian'       => 771,
        'Iogonek'       => 545,
        'Iota'       => 545,
        'Iotadieresis'       => 545,
        'Iotatonos'       => 705,
        'Itilde'       => 545,
        'J'       => 555,
        'Jaarmenian'       => 772,
        'Jcircumflex'       => 555,
        'Jheharmenian'       => 803,
        'K'       => 770,
        'Kadescendercyrillic'       => 770,
        'Kappa'       => 770,
        'Kaverticalstrokecyrillic'       => 770,
        'Kcommaaccent'       => 770,
        'Keharmenian'       => 792,
        'Kenarmenian'       => 793,
        'L'       => 637,
        'Lacute'       => 637,
        'Lambda'       => 776,
        'Lcaron'       => 637,
        'Lcommaaccent'       => 637,
        'Ldot'       => 637,
        'Liwnarmenian'       => 608,
        'Lslash'       => 642,
        'M'       => 947,
        'Menarmenian'       => 860,
        'Mu'       => 947,
        'N'       => 846,
        'Nacute'       => 846,
        'Ncaron'       => 846,
        'Ncommaaccent'       => 846,
        'Nowarmenian'       => 822,
        'Ntilde'       => 846,
        'Nu'       => 846,
        'O'       => 850,
        'OE'       => 1135,
        'Oacute'       => 850,
        'Obarredcyrillic'       => 850,
        'Obreve'       => 850,
        'Ocircumflex'       => 850,
        'Ocircumflexacute'       => 850,
        'Ocircumflexdotbelow'       => 850,
        'Ocircumflexgrave'       => 850,
        'Ocircumflexhookabove'       => 850,
        'Ocircumflextilde'       => 850,
        'Odieresis'       => 850,
        'Odotbelow'       => 850,
        'Ograve'       => 850,
        'Oharmenian'       => 850,
        'Ohookabove'       => 850,
        'Ohorn'       => 913,
        'Ohornacute'       => 913,
        'Ohorndotbelow'       => 913,
        'Ohorngrave'       => 913,
        'Ohornhookabove'       => 913,
        'Ohorntilde'       => 913,
        'Ohungarumlaut'       => 850,
        'Omacron'       => 850,
        'Omega'       => 843,
        'Omegatitlocyrillic'       => 1045,
        'Omegatonos'       => 970,
        'Omicron'       => 850,
        'Omicrontonos'       => 968,
        'Oslash'       => 850,
        'Oslashacute'       => 850,
        'Otilde'       => 850,
        'P'       => 732,
        'Peharmenian'       => 930,
        'Phi'       => 952,
        'Pi'       => 837,
        'Piwrarmenian'       => 952,
        'Psi'       => 976,
        'Q'       => 850,
        'R'       => 782,
        'Raarmenian'       => 860,
        'Racute'       => 782,
        'Rcaron'       => 782,
        'Rcommaaccent'       => 782,
        'Reharmenian'       => 765,
        'Rho'       => 732,
        'S'       => 710,
        'SF010000'       => 708,
        'SF020000'       => 708,
        'SF030000'       => 708,
        'SF040000'       => 708,
        'SF100000'       => 708,
        'SF110000'       => 708,
        'Sacute'       => 710,
        'Scaron'       => 710,
        'Scedilla'       => 710,
        'Schwa'       => 805,
        'Schwacyrillic'       => 805,
        'Scircumflex'       => 710,
        'Scommaaccent'       => 710,
        'Seharmenian'       => 812,
        'Shaarmenian'       => 740,
        'Shhacyrillic'       => 787,
        'Sigma'       => 683,
        'T'       => 681,
        'Tau'       => 681,
        'Tbar'       => 681,
        'Tcaron'       => 681,
        'Tcedilla'       => 681,
        'Tcommaaccent'       => 681,
        'Tedescendercyrillic'       => 681,
        'Tetsecyrillic'       => 990,
        'Theta'       => 850,
        'Thorn'       => 734,
        'Tiwnarmenian'       => 748,
        'Toarmenian'       => 1009,
        'U'       => 812,
        'Uacute'       => 812,
        'Ubreve'       => 812,
        'Ucircumflex'       => 812,
        'Udieresis'       => 812,
        'Udotbelow'       => 812,
        'Ugrave'       => 812,
        'Uhookabove'       => 812,
        'Uhorn'       => 846,
        'Uhornacute'       => 846,
        'Uhorndotbelow'       => 846,
        'Uhorngrave'       => 846,
        'Uhornhookabove'       => 846,
        'Uhorntilde'       => 846,
        'Uhungarumlaut'       => 812,
        'Ukcyrillic'       => 1352,
        'Umacron'       => 812,
        'Uogonek'       => 812,
        'Upsilon'       => 736,
        'Upsilondieresis'       => 736,
        'Upsilontonos'       => 939,
        'Uring'       => 812,
        'Ustraightcyrillic'       => 736,
        'Ustraightstrokecyrillic'       => 736,
        'Utilde'       => 812,
        'V'       => 763,
        'Vewarmenian'       => 822,
        'Voarmenian'       => 812,
        'W'       => 1128,
        'Wacute'       => 1128,
        'Wcircumflex'       => 1128,
        'Wdieresis'       => 1128,
        'Wgrave'       => 1128,
        'X'       => 763,
        'Xeharmenian'       => 986,
        'Xi'       => 714,
        'Y'       => 736,
        'Yacute'       => 736,
        'Ycircumflex'       => 736,
        'Ydieresis'       => 736,
        'Ydotbelow'       => 736,
        'Ygrave'       => 736,
        'Yhookabove'       => 736,
        'Yiarmenian'       => 756,
        'Yiwnarmenian'       => 605,
        'Ytilde'       => 736,
        'Z'       => 691,
        'Zaarmenian'       => 759,
        'Zacute'       => 691,
        'Zcaron'       => 691,
        'Zdotaccent'       => 691,
        'Zeta'       => 691,
        'Zhearmenian'       => 826,
        'Zhedescendercyrillic'       => 1115,
        'a'       => 667,
        'aacute'       => 667,
        'abbreviationmarkarmenian'       => 518,
        'abreve'       => 667,
        'abreveacute'       => 667,
        'abrevedotbelow'       => 667,
        'abrevegrave'       => 667,
        'abrevehookabove'       => 667,
        'abrevetilde'       => 667,
        'acircumflex'       => 667,
        'acircumflexacute'       => 667,
        'acircumflexdotbelow'       => 667,
        'acircumflexgrave'       => 667,
        'acircumflexhookabove'       => 667,
        'acircumflextilde'       => 667,
        'acute'       => 710,
        'acutecomb'       => 0,
        'adieresis'       => 667,
        'adotbelow'       => 667,
        'ae'       => 1018,
        'aeacute'       => 1018,
        'afii00208'       => 1000,
        'afii10017'       => 776,
        'afii10018'       => 757,
        'afii10019'       => 761,
        'afii10020'       => 637,
        'afii10021'       => 841,
        'afii10022'       => 683,
        'afii10023'       => 683,
        'afii10024'       => 1115,
        'afii10025'       => 706,
        'afii10026'       => 845,
        'afii10027'       => 845,
        'afii10028'       => 770,
        'afii10029'       => 845,
        'afii10030'       => 947,
        'afii10031'       => 837,
        'afii10032'       => 850,
        'afii10033'       => 837,
        'afii10034'       => 732,
        'afii10035'       => 723,
        'afii10036'       => 681,
        'afii10037'       => 736,
        'afii10038'       => 952,
        'afii10039'       => 763,
        'afii10040'       => 849,
        'afii10041'       => 787,
        'afii10042'       => 1163,
        'afii10043'       => 1177,
        'afii10044'       => 907,
        'afii10045'       => 1062,
        'afii10046'       => 757,
        'afii10047'       => 741,
        'afii10048'       => 1195,
        'afii10049'       => 794,
        'afii10050'       => 637,
        'afii10051'       => 910,
        'afii10052'       => 637,
        'afii10053'       => 741,
        'afii10054'       => 710,
        'afii10055'       => 545,
        'afii10056'       => 545,
        'afii10057'       => 555,
        'afii10058'       => 1222,
        'afii10059'       => 1214,
        'afii10060'       => 936,
        'afii10061'       => 770,
        'afii10062'       => 736,
        'afii10065'       => 667,
        'afii10066'       => 696,
        'afii10067'       => 677,
        'afii10068'       => 531,
        'afii10069'       => 691,
        'afii10070'       => 664,
        'afii10071'       => 664,
        'afii10072'       => 999,
        'afii10073'       => 587,
        'afii10074'       => 720,
        'afii10075'       => 720,
        'afii10076'       => 670,
        'afii10077'       => 709,
        'afii10078'       => 830,
        'afii10079'       => 719,
        'afii10080'       => 686,
        'afii10081'       => 719,
        'afii10082'       => 699,
        'afii10083'       => 598,
        'afii10084'       => 535,
        'afii10085'       => 650,
        'afii10086'       => 965,
        'afii10087'       => 668,
        'afii10088'       => 729,
        'afii10089'       => 684,
        'afii10090'       => 1002,
        'afii10091'       => 1012,
        'afii10092'       => 743,
        'afii10093'       => 937,
        'afii10094'       => 649,
        'afii10095'       => 605,
        'afii10096'       => 994,
        'afii10097'       => 681,
        'afii10098'       => 531,
        'afii10099'       => 712,
        'afii10100'       => 531,
        'afii10101'       => 605,
        'afii10102'       => 593,
        'afii10103'       => 341,
        'afii10104'       => 341,
        'afii10105'       => 402,
        'afii10106'       => 1012,
        'afii10107'       => 1019,
        'afii10108'       => 712,
        'afii10109'       => 670,
        'afii10110'       => 650,
        'afii10145'       => 837,
        'afii10193'       => 719,
        'afii10846'       => 664,
        'afii57636'       => 914,
        'afii61248'       => 1271,
        'afii61289'       => 414,
        'afii61352'       => 1293,
        'agrave'       => 667,
        'ahookabove'       => 667,
        'alpha'       => 699,
        'alphatonos'       => 699,
        'amacron'       => 667,
        'ampersand'       => 862,
        'anoteleia'       => 402,
        'aogonek'       => 667,
        'apostrophearmenian'       => 332,
        'approxequal'       => 867,
        'aring'       => 667,
        'aringacute'       => 667,
        'asciicircum'       => 867,
        'asciitilde'       => 867,
        'asterisk'       => 710,
        'at'       => 963,
        'atilde'       => 667,
        'aybarmenian'       => 1059,
        'b'       => 699,
        'backslash'       => 689,
        'bahtthai'       => 761,
        'bar'       => 543,
        'benarmenian'       => 712,
        'beta'       => 716,
        'braceleft'       => 710,
        'braceright'       => 710,
        'bracketleft'       => 543,
        'bracketright'       => 543,
        'breve'       => 710,
        'brevecmb'       => 710,
        'brokenbar'       => 543,
        'bullet'       => 710,
        'c'       => 588,
        'caarmenian'       => 702,
        'cacute'       => 588,
        'caron'       => 710,
        'caroncmb'       => 710,
        'ccaron'       => 588,
        'ccedilla'       => 588,
        'ccircumflex'       => 588,
        'cdotaccent'       => 588,
        'cedilla'       => 710,
        'cent'       => 710,
        'chaarmenian'       => 420,
        'cheabkhasiancyrillic'       => 788,
        'chedescenderabkhasiancyrillic'       => 788,
        'cheharmenian'       => 682,
        'cheverticalstrokecyrillic'       => 684,
        'chi'       => 635,
        'circumflex'       => 710,
        'circumflexcmb'       => 710,
        'coarmenian'       => 699,
        'colon'       => 402,
        'colonmonetary'       => 723,
        'comma'       => 361,
        'commaarmenian'       => 318,
        'copyright'       => 963,
        'cruzeiro'       => 723,
        'currency'       => 710,
        'd'       => 699,
        'daarmenian'       => 755,
        'dagger'       => 710,
        'daggerdbl'       => 710,
        'dbllowlinecmb'       => 0,
        'dcaron'       => 879,
        'dcroat'       => 699,
        'degree'       => 587,
        'delta'       => 686,
        'dieresis'       => 710,
        'dieresiscmb'       => 710,
        'dieresistonos'       => 710,
        'divide'       => 867,
        'dollar'       => 710,
        'dong'       => 699,
        'dotaccent'       => 710,
        'dotbelowcomb'       => 0,
        'dotlessi'       => 341,
        'dotlessj'       => 402,
        'e'       => 664,
        'eacute'       => 664,
        'ebreve'       => 664,
        'ecaron'       => 664,
        'echarmenian'       => 712,
        'echyiwnarmenian'       => 895,
        'ecircumflex'       => 664,
        'ecircumflexacute'       => 664,
        'ecircumflexdotbelow'       => 664,
        'ecircumflexgrave'       => 664,
        'ecircumflexhookabove'       => 664,
        'ecircumflextilde'       => 664,
        'edieresis'       => 664,
        'edotaccent'       => 664,
        'edotbelow'       => 664,
        'egrave'       => 664,
        'eharmenian'       => 627,
        'ehookabove'       => 664,
        'eight'       => 710,
        'eightinferior'       => 597,
        'eightsuperior'       => 597,
        'ellipsis'       => 1048,
        'emacron'       => 664,
        'emdash'       => 1000,
        'emphasismarkarmenian'       => 262,
        'endash'       => 710,
        'endescendercyrillic'       => 719,
        'eng'       => 712,
        'eogonek'       => 664,
        'epsilon'       => 584,
        'epsilontonos'       => 584,
        'equal'       => 867,
        'equivalence'       => 867,
        'estimated'       => 748,
        'eta'       => 712,
        'etarmenian'       => 712,
        'etatonos'       => 712,
        'eth'       => 679,
        'etilde'       => 664,
        'exclam'       => 402,
        'exclamarmenian'       => 250,
        'exclamdbl'       => 703,
        'exclamdown'       => 402,
        'f'       => 422,
        'feharmenian'       => 864,
        'ff'       => 825,
        'ffi'       => 1101,
        'ffl'       => 1104,
        'fi'       => 727,
        'figuredash'       => 710,
        'five'       => 710,
        'fiveeighths'       => 1181,
        'fiveinferior'       => 597,
        'fivesuperior'       => 597,
        'fl'       => 730,
        'florin'       => 710,
        'four'       => 710,
        'fourinferior'       => 597,
        'foursuperior'       => 597,
        'fraction'       => 439,
        'franc'       => 710,
        'g'       => 699,
        'gamma'       => 650,
        'gbreve'       => 699,
        'gcircumflex'       => 699,
        'gcommaaccent'       => 699,
        'gdotaccent'       => 699,
        'germandbls'       => 712,
        'ghadarmenian'       => 755,
        'ghestrokecyrillic'       => 531,
        'gimarmenian'       => 737,
        'grave'       => 710,
        'gravecomb'       => 0,
        'greater'       => 867,
        'greaterequal'       => 867,
        'guillemotleft'       => 849,
        'guillemotright'       => 849,
        'guilsinglleft'       => 543,
        'guilsinglright'       => 543,
        'h'       => 712,
        'haabkhasiancyrillic'       => 686,
        'hadescendercyrillic'       => 668,
        'hbar'       => 712,
        'hcircumflex'       => 712,
        'hoarmenian'       => 712,
        'hookabovecomb'       => 0,
        'hungarumlaut'       => 710,
        'hungarumlautcmb'       => 710,
        'hyphen'       => 479,
        'i'       => 341,
        'iacute'       => 341,
        'ibreve'       => 341,
        'icircumflex'       => 341,
        'idieresis'       => 341,
        'idotbelow'       => 341,
        'igrave'       => 341,
        'ihookabove'       => 341,
        'ij'       => 727,
        'imacron'       => 341,
        'infinity'       => 1058,
        'iniarmenian'       => 712,
        'integral'       => 538,
        'iogonek'       => 341,
        'iota'       => 341,
        'iotadieresis'       => 341,
        'iotadieresistonos'       => 341,
        'iotatonos'       => 341,
        'itilde'       => 341,
        'j'       => 402,
        'jaarmenian'       => 649,
        'jcircumflex'       => 402,
        'jheharmenian'       => 603,
        'k'       => 670,
        'kadescendercyrillic'       => 670,
        'kappa'       => 670,
        'kaverticalstrokecyrillic'       => 670,
        'kcommaaccent'       => 670,
        'keharmenian'       => 689,
        'kenarmenian'       => 712,
        'kgreenlandic'       => 670,
        'l'       => 341,
        'lacute'       => 341,
        'lambda'       => 650,
        'lcaron'       => 522,
        'lcommaaccent'       => 341,
        'ldot'       => 556,
        'less'       => 867,
        'lessequal'       => 867,
        'lira'       => 710,
        'liwnarmenian'       => 378,
        'logicalnot'       => 867,
        'longs'       => 344,
        'lozenge'       => 867,
        'lslash'       => 351,
        'm'       => 1058,
        'macron'       => 710,
        'menarmenian'       => 712,
        'minus'       => 867,
        'minute'       => 352,
        'mu'       => 721,
        'multiply'       => 867,
        'musicalnote'       => 500,
        'n'       => 712,
        'nacute'       => 712,
        'napostrophe'       => 825,
        'ncaron'       => 712,
        'ncommaaccent'       => 712,
        'nine'       => 710,
        'nineinferior'       => 597,
        'ninesuperior'       => 597,
        'notequal'       => 867,
        'nowarmenian'       => 716,
        'nsuperior'       => 597,
        'ntilde'       => 712,
        'nu'       => 649,
        'numbersign'       => 867,
        'o'       => 686,
        'oacute'       => 686,
        'obarredcyrillic'       => 686,
        'obreve'       => 686,
        'ocircumflex'       => 686,
        'ocircumflexacute'       => 686,
        'ocircumflexdotbelow'       => 686,
        'ocircumflexgrave'       => 686,
        'ocircumflexhookabove'       => 686,
        'ocircumflextilde'       => 686,
        'odieresis'       => 686,
        'odotbelow'       => 686,
        'oe'       => 1067,
        'ogonek'       => 710,
        'ograve'       => 686,
        'oharmenian'       => 686,
        'ohookabove'       => 686,
        'ohorn'       => 686,
        'ohornacute'       => 686,
        'ohorndotbelow'       => 686,
        'ohorngrave'       => 686,
        'ohornhookabove'       => 686,
        'ohorntilde'       => 686,
        'ohungarumlaut'       => 686,
        'omacron'       => 686,
        'omega'       => 894,
        'omega1'       => 708,
        'omegatitlocyrillic'       => 897,
        'omegatonos'       => 894,
        'omicron'       => 686,
        'omicrontonos'       => 686,
        'one'       => 710,
        'oneeighth'       => 1181,
        'onehalf'       => 1181,
        'oneinferior'       => 597,
        'onequarter'       => 1181,
        'onesuperior'       => 597,
        'openbullet'       => 354,
        'ordfeminine'       => 597,
        'ordmasculine'       => 597,
        'oslash'       => 686,
        'oslashacute'       => 686,
        'otilde'       => 686,
        'overline'       => 710,
        'p'       => 699,
        'paragraph'       => 710,
        'parenleft'       => 543,
        'parenright'       => 543,
        'partialdiff'       => 710,
        'peharmenian'       => 1059,
        'percent'       => 1271,
        'period'       => 361,
        'periodarmenian'       => 402,
        'periodcentered'       => 361,
        'perthousand'       => 1777,
        'peseta'       => 1343,
        'phi'       => 914,
        'pi'       => 719,
        'piwrarmenian'       => 1054,
        'plus'       => 867,
        'plusminus'       => 867,
        'product'       => 869,
        'psi'       => 941,
        'q'       => 699,
        'question'       => 616,
        'questionarmenian'       => 303,
        'questiondown'       => 616,
        'questiongreek'       => 402,
        'quotedbl'       => 587,
        'quotedblbase'       => 587,
        'quotedblleft'       => 587,
        'quotedblright'       => 587,
        'quoteleft'       => 332,
        'quotereversed'       => 332,
        'quoteright'       => 332,
        'quotesinglbase'       => 332,
        'quotesingle'       => 332,
        'r'       => 497,
        'raarmenian'       => 678,
        'racute'       => 497,
        'radical'       => 867,
        'rcaron'       => 497,
        'rcommaaccent'       => 497,
        'registered'       => 963,
        'reharmenian'       => 712,
        'rho'       => 699,
        'ring'       => 710,
        'ringhalfleftarmenian'       => 332,
        's'       => 593,
        'sacute'       => 593,
        'scaron'       => 593,
        'scedilla'       => 593,
        'schwa'       => 664,
        'scircumflex'       => 593,
        'scommaaccent'       => 593,
        'second'       => 616,
        'section'       => 710,
        'seharmenian'       => 712,
        'seven'       => 710,
        'seveneighths'       => 1181,
        'seveninferior'       => 597,
        'sevensuperior'       => 597,
        'shaarmenian'       => 504,
        'shhacyrillic'       => 712,
        'sigma'       => 725,
        'sigma1'       => 562,
        'six'       => 710,
        'sixinferior'       => 597,
        'sixsuperior'       => 597,
        'slash'       => 689,
        'space'       => 341,
        'sterling'       => 710,
        'summation'       => 698,
        't'       => 455,
        'tau'       => 535,
        'tbar'       => 455,
        'tcaron'       => 465,
        'tcedilla'       => 455,
        'tcommaaccent'       => 455,
        'tedescendercyrillic'       => 535,
        'tetsecyrillic'       => 815,
        'theta'       => 700,
        'thorn'       => 699,
        'three'       => 710,
        'threeeighths'       => 1181,
        'threeinferior'       => 597,
        'threequarters'       => 1181,
        'threesuperior'       => 597,
        'tilde'       => 710,
        'tildecomb'       => 0,
        'tiwnarmenian'       => 1054,
        'toarmenian'       => 922,
        'tonos'       => 710,
        'tprime'       => 616,
        'trademark'       => 963,
        'two'       => 710,
        'twoinferior'       => 597,
        'twosuperior'       => 597,
        'u'       => 712,
        'uacute'       => 712,
        'ubreve'       => 712,
        'ucircumflex'       => 712,
        'udieresis'       => 712,
        'udotbelow'       => 712,
        'ugrave'       => 712,
        'uhookabove'       => 712,
        'uhorn'       => 741,
        'uhornacute'       => 741,
        'uhorndotbelow'       => 741,
        'uhorngrave'       => 741,
        'uhornhookabove'       => 741,
        'uhorntilde'       => 741,
        'uhungarumlaut'       => 712,
        'ukcyrillic'       => 1227,
        'umacron'       => 712,
        'underscore'       => 710,
        'underscoredbl'       => 710,
        'uni0326'       => 363,
        'uni0347'       => 0,
        'uni040D'       => 845,
        'uni045D'       => 720,
        'uni0487'       => 635,
        'uni04F6'       => 637,
        'uni04F7'       => 531,
        'uni051A'       => 850,
        'uni051B'       => 699,
        'uni051C'       => 1128,
        'uni051D'       => 979,
        'uni058A'       => 479,
        'uni058F'       => 710,
        'uni1E9E'       => 747,
        'uni201F'       => 587,
        'uni202F'       => 170,
        'uni20A0'       => 710,
        'uni20A5'       => 1058,
        'uni20A6'       => 846,
        'uni20A8'       => 1339,
        'uni20AD'       => 770,
        'uni20AE'       => 681,
        'uni20AF'       => 1125,
        'uni20B0'       => 670,
        'uni20B1'       => 732,
        'uni20B2'       => 811,
        'uni20B3'       => 776,
        'uni20B4'       => 710,
        'uni20B5'       => 723,
        'uni20B8'       => 710,
        'uni20B9'       => 710,
        'uni20BA'       => 710,
        'uni20BB'       => 770,
        'uni20BC'       => 846,
        'uni20BD'       => 710,
        'uni20BE'       => 787,
        'uni20F0'       => 0,
        'uni2120'       => 1340,
        'uni2C6D'       => 831,
        'uni2C71'       => 740,
        'uni2C72'       => 1221,
        'uni2C73'       => 1059,
        'uniA71B'       => 507,
        'uniA71C'       => 507,
        'uniA71D'       => 313,
        'uniA71E'       => 313,
        'uniA71F'       => 313,
        'uniA788'       => 635,
        'uniA789'       => 402,
        'uniA78A'       => 532,
        'uniA78B'       => 332,
        'uniA78C'       => 332,
        'uniFB13'       => 1429,
        'uniFB14'       => 1429,
        'uniFB15'       => 1429,
        'uniFB16'       => 1775,
        'uniFB17'       => 1429,
        'uniFFFD'       => 927,
        'uogonek'       => 712,
        'upsilon'       => 706,
        'upsilondieresis'       => 706,
        'upsilondieresistonos'       => 706,
        'upsilontonos'       => 706,
        'uring'       => 712,
        'ustraightcyrillic'       => 650,
        'ustraightstrokecyrillic'       => 650,
        'utilde'       => 712,
        'v'       => 649,
        'vewarmenian'       => 741,
        'voarmenian'       => 712,
        'w'       => 979,
        'wacute'       => 979,
        'wcircumflex'       => 979,
        'wdieresis'       => 979,
        'wgrave'       => 979,
        'wonmonospace'       => 1128,
        'x'       => 668,
        'xeharmenian'       => 1063,
        'xi'       => 580,
        'y'       => 650,
        'yacute'       => 650,
        'ycircumflex'       => 650,
        'ydieresis'       => 650,
        'ydotbelow'       => 650,
        'yenmonospace'       => 710,
        'ygrave'       => 650,
        'yhookabove'       => 650,
        'yiarmenian'       => 351,
        'yiwnarmenian'       => 525,
        'ytilde'       => 650,
        'z'       => 596,
        'zaarmenian'       => 728,
        'zacute'       => 596,
        'zcaron'       => 596,
        'zdotaccent'       => 596,
        'zero'       => 710,
        'zeroinferior'       => 597,
        'zerosuperior'       => 597,
        'zeta'       => 549,
        'zhearmenian'       => 737,
        'zhedescendercyrillic'       => 999,
    },
    'wxold' => { # HORIZ. WIDTH TABLE
        'space' => '341',                        # C+0x20 # U+0x0020
        'exclam' => '402',                       # C+0x21 # U+0x0021
        'quotedbl' => '587',                     # C+0x22 # U+0x0022
        'numbersign' => '867',                   # C+0x23 # U+0x0023
        'dollar' => '710',                       # C+0x24 # U+0x0024
        'percent' => '1271',                     # C+0x25 # U+0x0025
        'ampersand' => '862',                    # C+0x26 # U+0x0026
        'quotesingle' => '332',                  # C+0x27 # U+0x0027
        'parenleft' => '543',                    # C+0x28 # U+0x0028
        'parenright' => '543',                   # C+0x29 # U+0x0029
        'asterisk' => '710',                     # C+0x2A # U+0x002A
        'plus' => '867',                         # C+0x2B # U+0x002B
        'comma' => '361',                        # C+0x2C # U+0x002C
        'hyphen' => '479',                       # C+0x2D # U+0x002D
        'period' => '361',                       # C+0x2E # U+0x002E
        'slash' => '689',                        # C+0x2F # U+0x002F
        'zero' => '710',                         # C+0x30 # U+0x0030
        'one' => '710',                          # C+0x31 # U+0x0031
        'two' => '710',                          # C+0x32 # U+0x0032
        'three' => '710',                        # C+0x33 # U+0x0033
        'four' => '710',                         # C+0x34 # U+0x0034
        'five' => '710',                         # C+0x35 # U+0x0035
        'six' => '710',                          # C+0x36 # U+0x0036
        'seven' => '710',                        # C+0x37 # U+0x0037
        'eight' => '710',                        # C+0x38 # U+0x0038
        'nine' => '710',                         # C+0x39 # U+0x0039
        'colon' => '402',                        # C+0x3A # U+0x003A
        'semicolon' => '402',                    # C+0x3B # U+0x003B
        'less' => '867',                         # C+0x3C # U+0x003C
        'equal' => '867',                        # C+0x3D # U+0x003D
        'greater' => '867',                      # C+0x3E # U+0x003E
        'question' => '616',                     # C+0x3F # U+0x003F
        'at' => '963',                           # C+0x40 # U+0x0040
        'A' => '776',                            # C+0x41 # U+0x0041
        'B' => '761',                            # C+0x42 # U+0x0042
        'C' => '723',                            # C+0x43 # U+0x0043
        'D' => '830',                            # C+0x44 # U+0x0044
        'E' => '683',                            # C+0x45 # U+0x0045
        'F' => '650',                            # C+0x46 # U+0x0046
        'G' => '811',                            # C+0x47 # U+0x0047
        'H' => '837',                            # C+0x48 # U+0x0048
        'I' => '545',                            # C+0x49 # U+0x0049
        'J' => '555',                            # C+0x4A # U+0x004A
        'K' => '770',                            # C+0x4B # U+0x004B
        'L' => '637',                            # C+0x4C # U+0x004C
        'M' => '947',                            # C+0x4D # U+0x004D
        'N' => '846',                            # C+0x4E # U+0x004E
        'O' => '850',                            # C+0x4F # U+0x004F
        'P' => '732',                            # C+0x50 # U+0x0050
        'Q' => '850',                            # C+0x51 # U+0x0051
        'R' => '782',                            # C+0x52 # U+0x0052
        'S' => '710',                            # C+0x53 # U+0x0053
        'T' => '681',                            # C+0x54 # U+0x0054
        'U' => '812',                            # C+0x55 # U+0x0055
        'V' => '763',                            # C+0x56 # U+0x0056
        'W' => '1128',                           # C+0x57 # U+0x0057
        'X' => '763',                            # C+0x58 # U+0x0058
        'Y' => '736',                            # C+0x59 # U+0x0059
        'Z' => '691',                            # C+0x5A # U+0x005A
        'bracketleft' => '543',                  # C+0x5B # U+0x005B
        'backslash' => '689',                    # C+0x5C # U+0x005C
        'bracketright' => '543',                 # C+0x5D # U+0x005D
        'asciicircum' => '867',                  # C+0x5E # U+0x005E
        'underscore' => '710',                   # C+0x5F # U+0x005F
        'grave' => '710',                        # C+0x60 # U+0x0060
        'a' => '667',                            # C+0x61 # U+0x0061
        'b' => '699',                            # C+0x62 # U+0x0062
        'c' => '588',                            # C+0x63 # U+0x0063
        'd' => '699',                            # C+0x64 # U+0x0064
        'e' => '664',                            # C+0x65 # U+0x0065
        'f' => '422',                            # C+0x66 # U+0x0066
        'g' => '699',                            # C+0x67 # U+0x0067
        'h' => '712',                            # C+0x68 # U+0x0068
        'i' => '341',                            # C+0x69 # U+0x0069
        'j' => '402',                            # C+0x6A # U+0x006A
        'k' => '670',                            # C+0x6B # U+0x006B
        'l' => '341',                            # C+0x6C # U+0x006C
        'm' => '1058',                           # C+0x6D # U+0x006D
        'n' => '712',                            # C+0x6E # U+0x006E
        'o' => '686',                            # C+0x6F # U+0x006F
        'p' => '699',                            # C+0x70 # U+0x0070
        'q' => '699',                            # C+0x71 # U+0x0071
        'r' => '497',                            # C+0x72 # U+0x0072
        's' => '593',                            # C+0x73 # U+0x0073
        't' => '455',                            # C+0x74 # U+0x0074
        'u' => '712',                            # C+0x75 # U+0x0075
        'v' => '649',                            # C+0x76 # U+0x0076
        'w' => '979',                            # C+0x77 # U+0x0077
        'x' => '668',                            # C+0x78 # U+0x0078
        'y' => '650',                            # C+0x79 # U+0x0079
        'z' => '596',                            # C+0x7A # U+0x007A
        'braceleft' => '710',                    # C+0x7B # U+0x007B
        'bar' => '543',                          # C+0x7C # U+0x007C
        'braceright' => '710',                   # C+0x7D # U+0x007D
        'asciitilde' => '867',                   # C+0x7E # U+0x007E
        'bullet' => '710',                       # C+0x7F # U+0x2022
        'Euro' => '710',                         # C+0x80 # U+0x20AC
        'quotesinglbase' => '332',               # C+0x82 # U+0x201A
        'florin' => '710',                       # C+0x83 # U+0x0192
        'quotedblbase' => '587',                 # C+0x84 # U+0x201E
        'ellipsis' => '1048',                    # C+0x85 # U+0x2026
        'dagger' => '710',                       # C+0x86 # U+0x2020
        'daggerdbl' => '710',                    # C+0x87 # U+0x2021
        'circumflex' => '710',                   # C+0x88 # U+0x02C6
        'perthousand' => '1777',                 # C+0x89 # U+0x2030
        'Scaron' => '710',                       # C+0x8A # U+0x0160
        'guilsinglleft' => '543',                # C+0x8B # U+0x2039
        'OE' => '1135',                          # C+0x8C # U+0x0152
        'Zcaron' => '691',                       # C+0x8E # U+0x017D
        'quoteleft' => '332',                    # C+0x91 # U+0x2018
        'quoteright' => '332',                   # C+0x92 # U+0x2019
        'quotedblleft' => '587',                 # C+0x93 # U+0x201C
        'quotedblright' => '587',                # C+0x94 # U+0x201D
        'endash' => '710',                       # C+0x96 # U+0x2013
        'emdash' => '1000',                      # C+0x97 # U+0x2014
        'tilde' => '710',                        # C+0x98 # U+0x02DC
        'trademark' => '963',                    # C+0x99 # U+0x2122
        'scaron' => '593',                       # C+0x9A # U+0x0161
        'guilsinglright' => '543',               # C+0x9B # U+0x203A
        'oe' => '1067',                          # C+0x9C # U+0x0153
        'zcaron' => '596',                       # C+0x9E # U+0x017E
        'Ydieresis' => '736',                    # C+0x9F # U+0x0178
        'exclamdown' => '402',                   # C+0xA1 # U+0x00A1
        'cent' => '710',                         # C+0xA2 # U+0x00A2
        'sterling' => '710',                     # C+0xA3 # U+0x00A3
        'currency' => '710',                     # C+0xA4 # U+0x00A4
        'yen' => '710',                          # C+0xA5 # U+0x00A5
        'brokenbar' => '543',                    # C+0xA6 # U+0x00A6
        'section' => '710',                      # C+0xA7 # U+0x00A7
        'dieresis' => '710',                     # C+0xA8 # U+0x00A8
        'copyright' => '963',                    # C+0xA9 # U+0x00A9
        'ordfeminine' => '597',                  # C+0xAA # U+0x00AA
        'guillemotleft' => '849',                # C+0xAB # U+0x00AB
        'logicalnot' => '867',                   # C+0xAC # U+0x00AC
        'registered' => '963',                   # C+0xAE # U+0x00AE
        'macron' => '710',                       # C+0xAF # U+0x00AF
        'degree' => '587',                       # C+0xB0 # U+0x00B0
        'plusminus' => '867',                    # C+0xB1 # U+0x00B1
        'twosuperior' => '597',                  # C+0xB2 # U+0x00B2
        'threesuperior' => '597',                # C+0xB3 # U+0x00B3
        'acute' => '710',                        # C+0xB4 # U+0x00B4
        'mu' => '721',                           # C+0xB5 # U+0x00B5
        'paragraph' => '710',                    # C+0xB6 # U+0x00B6
        'periodcentered' => '361',               # C+0xB7 # U+0x00B7
        'cedilla' => '710',                      # C+0xB8 # U+0x00B8
        'onesuperior' => '597',                  # C+0xB9 # U+0x00B9
        'ordmasculine' => '597',                 # C+0xBA # U+0x00BA
        'guillemotright' => '849',               # C+0xBB # U+0x00BB
        'onequarter' => '1181',                  # C+0xBC # U+0x00BC
        'onehalf' => '1181',                     # C+0xBD # U+0x00BD
        'threequarters' => '1181',               # C+0xBE # U+0x00BE
        'questiondown' => '616',                 # C+0xBF # U+0x00BF
        'Agrave' => '776',                       # C+0xC0 # U+0x00C0
        'Aacute' => '776',                       # C+0xC1 # U+0x00C1
        'Acircumflex' => '776',                  # C+0xC2 # U+0x00C2
        'Atilde' => '776',                       # C+0xC3 # U+0x00C3
        'Adieresis' => '776',                    # C+0xC4 # U+0x00C4
        'Aring' => '776',                        # C+0xC5 # U+0x00C5
        'AE' => '1093',                          # C+0xC6 # U+0x00C6
        'Ccedilla' => '723',                     # C+0xC7 # U+0x00C7
        'Egrave' => '683',                       # C+0xC8 # U+0x00C8
        'Eacute' => '683',                       # C+0xC9 # U+0x00C9
        'Ecircumflex' => '683',                  # C+0xCA # U+0x00CA
        'Edieresis' => '683',                    # C+0xCB # U+0x00CB
        'Igrave' => '545',                       # C+0xCC # U+0x00CC
        'Iacute' => '545',                       # C+0xCD # U+0x00CD
        'Icircumflex' => '545',                  # C+0xCE # U+0x00CE
        'Idieresis' => '545',                    # C+0xCF # U+0x00CF
        'Eth' => '830',                          # C+0xD0 # U+0x00D0
        'Ntilde' => '846',                       # C+0xD1 # U+0x00D1
        'Ograve' => '850',                       # C+0xD2 # U+0x00D2
        'Oacute' => '850',                       # C+0xD3 # U+0x00D3
        'Ocircumflex' => '850',                  # C+0xD4 # U+0x00D4
        'Otilde' => '850',                       # C+0xD5 # U+0x00D5
        'Odieresis' => '850',                    # C+0xD6 # U+0x00D6
        'multiply' => '867',                     # C+0xD7 # U+0x00D7
        'Oslash' => '850',                       # C+0xD8 # U+0x00D8
        'Ugrave' => '812',                       # C+0xD9 # U+0x00D9
        'Uacute' => '812',                       # C+0xDA # U+0x00DA
        'Ucircumflex' => '812',                  # C+0xDB # U+0x00DB
        'Udieresis' => '812',                    # C+0xDC # U+0x00DC
        'Yacute' => '736',                       # C+0xDD # U+0x00DD
        'Thorn' => '734',                        # C+0xDE # U+0x00DE
        'germandbls' => '712',                   # C+0xDF # U+0x00DF
        'agrave' => '667',                       # C+0xE0 # U+0x00E0
        'aacute' => '667',                       # C+0xE1 # U+0x00E1
        'acircumflex' => '667',                  # C+0xE2 # U+0x00E2
        'atilde' => '667',                       # C+0xE3 # U+0x00E3
        'adieresis' => '667',                    # C+0xE4 # U+0x00E4
        'aring' => '667',                        # C+0xE5 # U+0x00E5
        'ae' => '1018',                          # C+0xE6 # U+0x00E6
        'ccedilla' => '588',                     # C+0xE7 # U+0x00E7
        'egrave' => '664',                       # C+0xE8 # U+0x00E8
        'eacute' => '664',                       # C+0xE9 # U+0x00E9
        'ecircumflex' => '664',                  # C+0xEA # U+0x00EA
        'edieresis' => '664',                    # C+0xEB # U+0x00EB
        'igrave' => '341',                       # C+0xEC # U+0x00EC
        'iacute' => '341',                       # C+0xED # U+0x00ED
        'icircumflex' => '341',                  # C+0xEE # U+0x00EE
        'idieresis' => '341',                    # C+0xEF # U+0x00EF
        'eth' => '679',                          # C+0xF0 # U+0x00F0
        'ntilde' => '712',                       # C+0xF1 # U+0x00F1
        'ograve' => '686',                       # C+0xF2 # U+0x00F2
        'oacute' => '686',                       # C+0xF3 # U+0x00F3
        'ocircumflex' => '686',                  # C+0xF4 # U+0x00F4
        'otilde' => '686',                       # C+0xF5 # U+0x00F5
        'odieresis' => '686',                    # C+0xF6 # U+0x00F6
        'divide' => '867',                       # C+0xF7 # U+0x00F7
        'oslash' => '686',                       # C+0xF8 # U+0x00F8
        'ugrave' => '712',                       # C+0xF9 # U+0x00F9
        'uacute' => '712',                       # C+0xFA # U+0x00FA
        'ucircumflex' => '712',                  # C+0xFB # U+0x00FB
        'udieresis' => '712',                    # C+0xFC # U+0x00FC
        'yacute' => '650',                       # C+0xFD # U+0x00FD
        'thorn' => '699',                        # C+0xFE # U+0x00FE
        'ydieresis' => '650',                    # C+0xFF # U+0x00FF
        'middot' => '361',                       # U+0x00B7
        'Amacron' => '776',                      # U+0x0100
        'amacron' => '667',                      # U+0x0101
        'Abreve' => '776',                       # U+0x0102
        'abreve' => '667',                       # U+0x0103
        'Aogonek' => '776',                      # U+0x0104
        'aogonek' => '667',                      # U+0x0105
        'Cacute' => '723',                       # U+0x0106
        'cacute' => '588',                       # U+0x0107
        'Ccircumflex' => '723',                  # U+0x0108
        'ccircumflex' => '588',                  # U+0x0109
        'Cdot' => '723',                         # U+0x010A
        'cdot' => '588',                         # U+0x010B
        'Ccaron' => '723',                       # U+0x010C
        'ccaron' => '588',                       # U+0x010D
        'Dcaron' => '830',                       # U+0x010E
        'dcaron' => '879',                       # U+0x010F
        'Emacron' => '683',                      # U+0x0112
        'emacron' => '664',                      # U+0x0113
        'Ebreve' => '683',                       # U+0x0114
        'ebreve' => '664',                       # U+0x0115
        'Edot' => '683',                         # U+0x0116
        'edot' => '664',                         # U+0x0117
        'Eogonek' => '683',                      # U+0x0118
        'eogonek' => '664',                      # U+0x0119
        'Ecaron' => '683',                       # U+0x011A
        'ecaron' => '664',                       # U+0x011B
        'Gcircumflex' => '811',                  # U+0x011C
        'gcircumflex' => '699',                  # U+0x011D
        'Gbreve' => '811',                       # U+0x011E
        'gbreve' => '699',                       # U+0x011F
        'Gdot' => '811',                         # U+0x0120
        'gdot' => '699',                         # U+0x0121
        'Hcircumflex' => '837',                  # U+0x0124
        'hcircumflex' => '712',                  # U+0x0125
        'Hbar' => '837',                         # U+0x0126
        'hbar' => '712',                         # U+0x0127
        'Itilde' => '545',                       # U+0x0128
        'itilde' => '341',                       # U+0x0129
        'Imacron' => '545',                      # U+0x012A
        'imacron' => '341',                      # U+0x012B
        'Ibreve' => '545',                       # U+0x012C
        'ibreve' => '341',                       # U+0x012D
        'Iogonek' => '545',                      # U+0x012E
        'iogonek' => '341',                      # U+0x012F
        'Idot' => '545',                         # U+0x0130
        'dotlessi' => '341',                     # U+0x0131
        'IJ' => '1007',                          # U+0x0132
        'ij' => '727',                           # U+0x0133
        'Jcircumflex' => '555',                  # U+0x0134
        'jcircumflex' => '402',                  # U+0x0135
        'kgreenlandic' => '670',                 # U+0x0138
        'Lacute' => '637',                       # U+0x0139
        'lacute' => '341',                       # U+0x013A
        'Lcaron' => '637',                       # U+0x013D
        'lcaron' => '522',                       # U+0x013E
        'Ldot' => '637',                         # U+0x013F
        'ldot' => '556',                         # U+0x0140
        'Lslash' => '642',                       # U+0x0141
        'lslash' => '351',                       # U+0x0142
        'Nacute' => '846',                       # U+0x0143
        'nacute' => '712',                       # U+0x0144
        'Ncaron' => '846',                       # U+0x0147
        'ncaron' => '712',                       # U+0x0148
        'napostrophe' => '825',                  # U+0x0149
        'Eng' => '846',                          # U+0x014A
        'eng' => '712',                          # U+0x014B
        'Omacron' => '850',                      # U+0x014C
        'omacron' => '686',                      # U+0x014D
        'Obreve' => '850',                       # U+0x014E
        'obreve' => '686',                       # U+0x014F
        'Racute' => '782',                       # U+0x0154
        'racute' => '497',                       # U+0x0155
        'Rcaron' => '782',                       # U+0x0158
        'rcaron' => '497',                       # U+0x0159
        'Sacute' => '710',                       # U+0x015A
        'sacute' => '593',                       # U+0x015B
        'Scircumflex' => '710',                  # U+0x015C
        'scircumflex' => '593',                  # U+0x015D
        'Scedilla' => '710',                     # U+0x015E
        'scedilla' => '593',                     # U+0x015F
        'Tcaron' => '681',                       # U+0x0164
        'tcaron' => '465',                       # U+0x0165
        'Tbar' => '681',                         # U+0x0166
        'tbar' => '455',                         # U+0x0167
        'Utilde' => '812',                       # U+0x0168
        'utilde' => '712',                       # U+0x0169
        'Umacron' => '812',                      # U+0x016A
        'umacron' => '712',                      # U+0x016B
        'Ubreve' => '812',                       # U+0x016C
        'ubreve' => '712',                       # U+0x016D
        'Uring' => '812',                        # U+0x016E
        'uring' => '712',                        # U+0x016F
        'Uogonek' => '812',                      # U+0x0172
        'uogonek' => '712',                      # U+0x0173
        'Wcircumflex' => '1128',                 # U+0x0174
        'wcircumflex' => '979',                  # U+0x0175
        'Ycircumflex' => '736',                  # U+0x0176
        'ycircumflex' => '650',                  # U+0x0177
        'Zacute' => '691',                       # U+0x0179
        'zacute' => '596',                       # U+0x017A
        'Zdot' => '691',                         # U+0x017B
        'zdot' => '596',                         # U+0x017C
        'longs' => '344',                        # U+0x017F
        'Ohorn' => '913',                        # U+0x01A0
        'ohorn' => '686',                        # U+0x01A1
        'Uhorn' => '846',                        # U+0x01AF
        'uhorn' => '741',                        # U+0x01B0
        'Aringacute' => '776',                   # U+0x01FA
        'aringacute' => '667',                   # U+0x01FB
        'AEacute' => '1093',                     # U+0x01FC
        'aeacute' => '1018',                     # U+0x01FD
        'Oslashacute' => '850',                  # U+0x01FE
        'oslashacute' => '686',                  # U+0x01FF
        'caron' => '710',                        # U+0x02C7
        'breve' => '710',                        # U+0x02D8
        'dotaccent' => '710',                    # U+0x02D9
        'ring' => '710',                         # U+0x02DA
        'ogonek' => '710',                       # U+0x02DB
        'hungarumlaut' => '710',                 # U+0x02DD
        'dblgravecmb' => '710',                  # U+0x030F
        'gravecomb' => '0',                      # U+0x0300
        'acutecomb' => '0',                      # U+0x0301
        'tildecomb' => '0',                      # U+0x0303
        'hookabovecomb' => '0',                  # U+0x0309
        'dotbelowcomb' => '0',                   # U+0x0323
        'tonos' => '710',                        # U+0x0384
        'dieresistonos' => '710',                # U+0x0385
        'Alphatonos' => '797',                   # U+0x0386
        'anoteleia' => '402',                    # U+0x0387
        'Epsilontonos' => '847',                 # U+0x0388
        'Etatonos' => '1000',                    # U+0x0389
        'Iotatonos' => '705',                    # U+0x038A
        'Omicrontonos' => '968',                 # U+0x038C
        'Upsilontonos' => '939',                 # U+0x038E
        'Omegatonos' => '970',                   # U+0x038F
        'iotadieresistonos' => '341',            # U+0x0390
        'Alpha' => '776',                        # U+0x0391
        'Beta' => '761',                         # U+0x0392
        'Gamma' => '637',                        # U+0x0393
        'Delta' => '805',                        # U+0x0394
        'Epsilon' => '683',                      # U+0x0395
        'Zeta' => '691',                         # U+0x0396
        'Eta' => '837',                          # U+0x0397
        'Theta' => '850',                        # U+0x0398
        'Iota' => '545',                         # U+0x0399
        'Kappa' => '770',                        # U+0x039A
        'Lambda' => '776',                       # U+0x039B
        'Mu' => '947',                           # U+0x039C
        'Nu' => '846',                           # U+0x039D
        'Xi' => '714',                           # U+0x039E
        'Omicron' => '850',                      # U+0x039F
        'Pi' => '837',                           # U+0x03A0
        'Rho' => '732',                          # U+0x03A1
        'Sigma' => '683',                        # U+0x03A3
        'Tau' => '681',                          # U+0x03A4
        'Upsilon' => '736',                      # U+0x03A5
        'Phi' => '952',                          # U+0x03A6
        'Chi' => '763',                          # U+0x03A7
        'Psi' => '976',                          # U+0x03A8
        'Omega' => '843',                        # U+0x03A9
        'Iotadieresis' => '545',                 # U+0x03AA
        'Upsilondieresis' => '736',              # U+0x03AB
        'alphatonos' => '699',                   # U+0x03AC
        'epsilontonos' => '584',                 # U+0x03AD
        'etatonos' => '712',                     # U+0x03AE
        'iotatonos' => '341',                    # U+0x03AF
        'upsilondieresistonos' => '706',         # U+0x03B0
        'alpha' => '699',                        # U+0x03B1
        'beta' => '716',                         # U+0x03B2
        'gamma' => '650',                        # U+0x03B3
        'delta' => '686',                        # U+0x03B4
        'epsilon' => '584',                      # U+0x03B5
        'zeta' => '549',                         # U+0x03B6
        'eta' => '712',                          # U+0x03B7
        'theta' => '700',                        # U+0x03B8
        'iota' => '341',                         # U+0x03B9
        'kappa' => '670',                        # U+0x03BA
        'lambda' => '650',                       # U+0x03BB
        'nu' => '649',                           # U+0x03BD
        'xi' => '580',                           # U+0x03BE
        'omicron' => '686',                      # U+0x03BF
        'pi' => '719',                           # U+0x03C0
        'rho' => '699',                          # U+0x03C1
        'sigma1' => '562',                       # U+0x03C2
        'sigma' => '725',                        # U+0x03C3
        'tau' => '535',                          # U+0x03C4
        'upsilon' => '706',                      # U+0x03C5
        'phi' => '914',                          # U+0x03C6
        'chi' => '635',                          # U+0x03C7
        'psi' => '941',                          # U+0x03C8
        'omega' => '894',                        # U+0x03C9
        'iotadieresis' => '341',                 # U+0x03CA
        'upsilondieresis' => '706',              # U+0x03CB
        'omicrontonos' => '686',                 # U+0x03CC
        'upsilontonos' => '706',                 # U+0x03CD
        'omegatonos' => '894',                   # U+0x03CE
        'afii10023' => '683',                    # U+0x0401
        'afii10051' => '910',                    # U+0x0402
        'afii10052' => '637',                    # U+0x0403
        'afii10053' => '741',                    # U+0x0404
        'afii10054' => '710',                    # U+0x0405
        'afii10055' => '545',                    # U+0x0406
        'afii10056' => '545',                    # U+0x0407
        'afii10057' => '555',                    # U+0x0408
        'afii10058' => '1222',                   # U+0x0409
        'afii10059' => '1214',                   # U+0x040A
        'afii10060' => '936',                    # U+0x040B
        'afii10061' => '770',                    # U+0x040C
        'afii10062' => '736',                    # U+0x040E
        'afii10145' => '837',                    # U+0x040F
        'afii10017' => '776',                    # U+0x0410
        'afii10018' => '757',                    # U+0x0411
        'afii10019' => '761',                    # U+0x0412
        'afii10020' => '637',                    # U+0x0413
        'afii10021' => '841',                    # U+0x0414
        'afii10022' => '683',                    # U+0x0415
        'afii10024' => '1115',                   # U+0x0416
        'afii10025' => '706',                    # U+0x0417
        'afii10026' => '845',                    # U+0x0418
        'afii10027' => '845',                    # U+0x0419
        'afii10028' => '770',                    # U+0x041A
        'afii10029' => '845',                    # U+0x041B
        'afii10030' => '947',                    # U+0x041C
        'afii10031' => '837',                    # U+0x041D
        'afii10032' => '850',                    # U+0x041E
        'afii10033' => '837',                    # U+0x041F
        'afii10034' => '732',                    # U+0x0420
        'afii10035' => '723',                    # U+0x0421
        'afii10036' => '681',                    # U+0x0422
        'afii10037' => '736',                    # U+0x0423
        'afii10038' => '952',                    # U+0x0424
        'afii10039' => '763',                    # U+0x0425
        'afii10040' => '849',                    # U+0x0426
        'afii10041' => '787',                    # U+0x0427
        'afii10042' => '1163',                   # U+0x0428
        'afii10043' => '1177',                   # U+0x0429
        'afii10044' => '907',                    # U+0x042A
        'afii10045' => '1062',                   # U+0x042B
        'afii10046' => '757',                    # U+0x042C
        'afii10047' => '741',                    # U+0x042D
        'afii10048' => '1195',                   # U+0x042E
        'afii10049' => '794',                    # U+0x042F
        'afii10065' => '667',                    # U+0x0430
        'afii10066' => '696',                    # U+0x0431
        'afii10067' => '677',                    # U+0x0432
        'afii10068' => '531',                    # U+0x0433
        'afii10069' => '691',                    # U+0x0434
        'afii10070' => '664',                    # U+0x0435
        'afii10072' => '999',                    # U+0x0436
        'afii10073' => '587',                    # U+0x0437
        'afii10074' => '720',                    # U+0x0438
        'afii10075' => '720',                    # U+0x0439
        'afii10076' => '670',                    # U+0x043A
        'afii10077' => '709',                    # U+0x043B
        'afii10078' => '830',                    # U+0x043C
        'afii10079' => '719',                    # U+0x043D
        'afii10080' => '686',                    # U+0x043E
        'afii10081' => '719',                    # U+0x043F
        'afii10082' => '699',                    # U+0x0440
        'afii10083' => '598',                    # U+0x0441
        'afii10084' => '535',                    # U+0x0442
        'afii10085' => '650',                    # U+0x0443
        'afii10086' => '965',                    # U+0x0444
        'afii10087' => '668',                    # U+0x0445
        'afii10088' => '729',                    # U+0x0446
        'afii10089' => '684',                    # U+0x0447
        'afii10090' => '1002',                   # U+0x0448
        'afii10091' => '1012',                   # U+0x0449
        'afii10092' => '743',                    # U+0x044A
        'afii10093' => '937',                    # U+0x044B
        'afii10094' => '649',                    # U+0x044C
        'afii10095' => '605',                    # U+0x044D
        'afii10096' => '994',                    # U+0x044E
        'afii10097' => '681',                    # U+0x044F
        'afii10071' => '664',                    # U+0x0451
        'afii10099' => '712',                    # U+0x0452
        'afii10100' => '531',                    # U+0x0453
        'afii10101' => '605',                    # U+0x0454
        'afii10102' => '593',                    # U+0x0455
        'afii10103' => '341',                    # U+0x0456
        'afii10104' => '341',                    # U+0x0457
        'afii10105' => '402',                    # U+0x0458
        'afii10106' => '1012',                   # U+0x0459
        'afii10107' => '1019',                   # U+0x045A
        'afii10108' => '712',                    # U+0x045B
        'afii10109' => '670',                    # U+0x045C
        'afii10110' => '650',                    # U+0x045E
        'afii10193' => '719',                    # U+0x045F
        'afii10050' => '637',                    # U+0x0490
        'afii10098' => '531',                    # U+0x0491
        'Wgrave' => '1128',                      # U+0x1E80
        'wgrave' => '979',                       # U+0x1E81
        'Wacute' => '1128',                      # U+0x1E82
        'wacute' => '979',                       # U+0x1E83
        'Wdieresis' => '1128',                   # U+0x1E84
        'wdieresis' => '979',                    # U+0x1E85
        'Ygrave' => '736',                       # U+0x1EF2
        'ygrave' => '650',                       # U+0x1EF3
        'afii00208' => '1000',                   # U+0x2015
        'underscoredbl' => '710',                # U+0x2017
        'quotereversed' => '332',                # U+0x201B
        'minute' => '352',                       # U+0x2032
        'second' => '616',                       # U+0x2033
        'exclamdbl' => '703',                    # U+0x203C
        'fraction' => '439',                     # U+0x2044
        'foursuperior' => '597',                 # U+0x2074
        'fivesuperior' => '597',                 # U+0x2075
        'sevensuperior' => '597',                # U+0x2077
        'eightsuperior' => '597',                # U+0x2078
        'nsuperior' => '597',                    # U+0x207F
        'franc' => '710',                        # U+0x20A3
        'peseta' => '1343',                      # U+0x20A7
        'dong' => '699',                         # U+0x20AB
        'afii61248' => '1271',                   # U+0x2105
        'afii61289' => '414',                    # U+0x2113
        'afii61352' => '1293',                   # U+0x2116
        'estimated' => '748',                    # U+0x212E
# gimel was 0 width, still doesn't show up
        'gimel' => '620',                        # U+0x2137
        'oneeighth' => '1181',                   # U+0x215B
        'threeeighths' => '1181',                # U+0x215C
        'fiveeighths' => '1181',                 # U+0x215D
        'seveneighths' => '1181',                # U+0x215E
        'partialdiff' => '710',                  # U+0x2202
        'product' => '869',                      # U+0x220F
        'summation' => '698',                    # U+0x2211
        'minus' => '867',                        # U+0x2212
        'radical' => '867',                      # U+0x221A
        'infinity' => '1058',                    # U+0x221E
        'integral' => '538',                     # U+0x222B
        'approxequal' => '867',                  # U+0x2248
        'notequal' => '867',                     # U+0x2260
        'lessequal' => '867',                    # U+0x2264
        'greaterequal' => '867',                 # U+0x2265
        'H22073' => '604',                       # U+0x25A1
        'H18543' => '354',                       # U+0x25AA
        'H18551' => '354',                       # U+0x25AB
        'lozenge' => '867',                      # U+0x25CA
        'H18533' => '604',                       # U+0x25CF
        'openbullet' => '354',                   # U+0x25E6
        'commaaccent' => '332',                  # U+0xF6C3
        'radicalex' => '710',                    # U+0xF8E5
        'fi' => '727',                           # U+0xFB01
        'fl' => '730',                           # U+0xFB02
    }, # HORIZ. WIDTH TABLE
} };

1;
