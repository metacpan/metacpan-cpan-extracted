package PDF::Builder::Resource::Font::CoreFont::trebuchetbolditalic;

use strict;
use warnings;

our $VERSION = '3.022'; # VERSION
my $LAST_UPDATE = '3.018'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::Font::CoreFont::trebuchetbolditalic - font-specific information for bold weight + italic Trebuchet font
(I<not> standard PDF core)

=cut

sub data { return {
    'fontname' => 'TrebuchetMS,BoldItalic',
    'type' => 'TrueType',
    'apiname' => 'TrBoIt',
    'ascender' => '938',
    'capheight' => '715',
    'descender' => '-222',
    'isfixedpitch' => '0',
    'issymbol' => '0',
    'italicangle' => '-10',
    'underlineposition' => '-261',
    'underlinethickness' => '200',
    'xheight' => '522',
    'firstchar' => '32',
    'lastchar' => '255',
    'flags' => '262242',
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
    'fontbbox' => [ -107, -269, 1155, 965 ],
# source: \Windows\Fonts\trebucbi.ttf
# font underline position = -261
# CIDs 0 .. 1167 to be output
# fontbbox = (-491 -278 1410 991)
    'wx' => { # HORIZ. WIDTH TABLE
        'A'       => 613,
        'AE'       => 959,
        'AEacute'       => 959,
        'Aacute'       => 613,
        'Abreve'       => 613,
        'Acircumflex'       => 613,
        'Adieresis'       => 613,
        'Agrave'       => 613,
        'Alpha'       => 625,
        'Alphatonos'       => 625,
        'Amacron'       => 613,
        'Aogonek'       => 613,
        'Aring'       => 613,
        'Aringacute'       => 613,
        'Atilde'       => 613,
        'Aybarmenian'       => 697,
        'B'       => 589,
        'Benarmenian'       => 666,
        'Beta'       => 600,
        'C'       => 612,
        'Caarmenian'       => 708,
        'Cacute'       => 612,
        'Ccaron'       => 612,
        'Ccedilla'       => 612,
        'Ccircumflex'       => 612,
        'Cdotaccent'       => 612,
        'Chaarmenian'       => 680,
        'Cheharmenian'       => 706,
        'Chi'       => 645,
        'Coarmenian'       => 675,
        'D'       => 632,
        'Daarmenian'       => 668,
        'Dcaron'       => 632,
        'Dcroat'       => 654,
        'Delta'       => 584,
        'E'       => 593,
        'Eacute'       => 593,
        'Ebreve'       => 593,
        'Ecaron'       => 593,
        'Echarmenian'       => 658,
        'Ecircumflex'       => 593,
        'Edieresis'       => 593,
        'Edotaccent'       => 593,
        'Egrave'       => 593,
        'Eharmenian'       => 608,
        'Emacron'       => 593,
        'Eng'       => 672,
        'Eogonek'       => 593,
        'Epsilon'       => 581,
        'Epsilontonos'       => 645,
        'Eta'       => 678,
        'Etarmenian'       => 666,
        'Etatonos'       => 743,
        'Eth'       => 654,
        'Euro'       => 585,
        'F'       => 585,
        'Feharmenian'       => 826,
        'G'       => 676,
        'Gamma'       => 549,
        'Gbreve'       => 676,
        'Gcircumflex'       => 676,
        'Gcommaaccent'       => 676,
        'Gdotaccent'       => 676,
        'Ghadarmenian'       => 664,
        'Gimarmenian'       => 682,
        'H'       => 678,
        'H18533'       => 604,
        'H18543'       => 354,
        'H18551'       => 354,
        'H22073'       => 604,
        'Hbar'       => 699,
        'Hcircumflex'       => 678,
        'Hoarmenian'       => 586,
        'I'       => 278,
        'IJ'       => 756,
        'Iacute'       => 278,
        'Ibreve'       => 278,
        'Icircumflex'       => 278,
        'Idieresis'       => 278,
        'Idotaccent'       => 278,
        'Igrave'       => 278,
        'Imacron'       => 278,
        'Iniarmenian'       => 638,
        'Iogonek'       => 278,
        'Iota'       => 277,
        'Iotadieresis'       => 277,
        'Iotatonos'       => 335,
        'Itilde'       => 278,
        'J'       => 498,
        'Jaarmenian'       => 706,
        'Jcircumflex'       => 498,
        'Jheharmenian'       => 709,
        'K'       => 649,
        'Kappa'       => 623,
        'Kcommaaccent'       => 649,
        'Keharmenian'       => 708,
        'Kenarmenian'       => 643,
        'L'       => 528,
        'Lacute'       => 528,
        'Lambda'       => 629,
        'Lcaron'       => 528,
        'Lcommaaccent'       => 528,
        'Ldot'       => 528,
        'Liwnarmenian'       => 528,
        'Lslash'       => 528,
        'M'       => 786,
        'Menarmenian'       => 709,
        'Mu'       => 787,
        'N'       => 660,
        'Nacute'       => 660,
        'Ncaron'       => 660,
        'Ncommaaccent'       => 660,
        'Nowarmenian'       => 660,
        'Ntilde'       => 660,
        'Nu'       => 660,
        'O'       => 702,
        'OE'       => 1058,
        'Oacute'       => 702,
        'Obreve'       => 702,
        'Ocircumflex'       => 702,
        'Odieresis'       => 702,
        'Ograve'       => 702,
        'Oharmenian'       => 712,
        'Ohungarumlaut'       => 702,
        'Omacron'       => 702,
        'Omega'       => 668,
        'Omegatonos'       => 766,
        'Omicron'       => 702,
        'Omicrontonos'       => 737,
        'Oslash'       => 702,
        'Oslashacute'       => 702,
        'Otilde'       => 702,
        'P'       => 583,
        'Peharmenian'       => 804,
        'Phi'       => 808,
        'Pi'       => 657,
        'Piwrarmenian'       => 846,
        'Psi'       => 829,
        'Q'       => 769,
        'R'       => 623,
        'Raarmenian'       => 703,
        'Racute'       => 623,
        'Rcaron'       => 623,
        'Rcommaaccent'       => 623,
        'Reharmenian'       => 631,
        'Rho'       => 589,
        'S'       => 501,
        'Sacute'       => 501,
        'Scaron'       => 501,
        'Scedilla'       => 501,
        'Scircumflex'       => 501,
        'Scommaaccent'       => 501,
        'Seharmenian'       => 666,
        'Shaarmenian'       => 667,
        'Sigma'       => 622,
        'T'       => 685,
        'Tau'       => 651,
        'Tbar'       => 685,
        'Tcaron'       => 685,
        'Tcedilla'       => 685,
        'Tcommaaccent'       => 685,
        'Theta'       => 717,
        'Thorn'       => 561,
        'Tiwnarmenian'       => 650,
        'Toarmenian'       => 869,
        'U'       => 661,
        'Uacute'       => 661,
        'Ubreve'       => 661,
        'Ucircumflex'       => 661,
        'Udieresis'       => 661,
        'Ugrave'       => 661,
        'Uhungarumlaut'       => 661,
        'Umacron'       => 661,
        'Uogonek'       => 661,
        'Upsilon'       => 606,
        'Upsilondieresis'       => 606,
        'Upsilontonos'       => 701,
        'Uring'       => 661,
        'Utilde'       => 661,
        'V'       => 683,
        'Vewarmenian'       => 658,
        'Voarmenian'       => 666,
        'W'       => 926,
        'Wacute'       => 926,
        'Wcircumflex'       => 926,
        'Wdieresis'       => 926,
        'Wgrave'       => 926,
        'X'       => 656,
        'Xeharmenian'       => 868,
        'Xi'       => 651,
        'Y'       => 683,
        'Yacute'       => 683,
        'Ycircumflex'       => 683,
        'Ydieresis'       => 683,
        'Ygrave'       => 683,
        'Yiarmenian'       => 653,
        'Yiwnarmenian'       => 507,
        'Z'       => 611,
        'Zaarmenian'       => 705,
        'Zacute'       => 611,
        'Zcaron'       => 611,
        'Zdotaccent'       => 611,
        'Zeta'       => 588,
        'Zhearmenian'       => 682,
        'a'       => 592,
        'aacute'       => 592,
        'abbreviationmarkarmenian'       => 0,
        'abreve'       => 592,
        'acircumflex'       => 592,
        'acute'       => 585,
        'adieresis'       => 592,
        'ae'       => 893,
        'aeacute'       => 893,
        'afii00208'       => 734,
        'afii10017'       => 633,
        'afii10018'       => 592,
        'afii10019'       => 595,
        'afii10020'       => 556,
        'afii10021'       => 741,
        'afii10022'       => 575,
        'afii10023'       => 575,
        'afii10024'       => 940,
        'afii10025'       => 548,
        'afii10026'       => 696,
        'afii10027'       => 696,
        'afii10028'       => 638,
        'afii10029'       => 706,
        'afii10030'       => 792,
        'afii10031'       => 679,
        'afii10032'       => 703,
        'afii10033'       => 655,
        'afii10034'       => 587,
        'afii10035'       => 585,
        'afii10036'       => 657,
        'afii10037'       => 620,
        'afii10038'       => 791,
        'afii10039'       => 632,
        'afii10040'       => 674,
        'afii10041'       => 628,
        'afii10042'       => 920,
        'afii10043'       => 956,
        'afii10044'       => 786,
        'afii10045'       => 828,
        'afii10046'       => 604,
        'afii10047'       => 597,
        'afii10048'       => 940,
        'afii10049'       => 628,
        'afii10050'       => 556,
        'afii10051'       => 767,
        'afii10052'       => 556,
        'afii10053'       => 588,
        'afii10054'       => 511,
        'afii10055'       => 277,
        'afii10056'       => 277,
        'afii10057'       => 496,
        'afii10058'       => 1025,
        'afii10059'       => 950,
        'afii10060'       => 785,
        'afii10061'       => 638,
        'afii10062'       => 620,
        'afii10065'       => 557,
        'afii10066'       => 585,
        'afii10067'       => 562,
        'afii10068'       => 487,
        'afii10069'       => 604,
        'afii10070'       => 543,
        'afii10071'       => 543,
        'afii10072'       => 783,
        'afii10073'       => 482,
        'afii10074'       => 580,
        'afii10075'       => 580,
        'afii10076'       => 547,
        'afii10077'       => 608,
        'afii10078'       => 757,
        'afii10079'       => 587,
        'afii10080'       => 568,
        'afii10081'       => 579,
        'afii10082'       => 583,
        'afii10083'       => 490,
        'afii10084'       => 860,
        'afii10085'       => 534,
        'afii10086'       => 793,
        'afii10087'       => 570,
        'afii10088'       => 594,
        'afii10089'       => 566,
        'afii10090'       => 848,
        'afii10091'       => 868,
        'afii10092'       => 642,
        'afii10093'       => 753,
        'afii10094'       => 538,
        'afii10095'       => 488,
        'afii10096'       => 763,
        'afii10097'       => 559,
        'afii10098'       => 464,
        'afii10099'       => 582,
        'afii10100'       => 487,
        'afii10101'       => 493,
        'afii10102'       => 456,
        'afii10103'       => 312,
        'afii10104'       => 312,
        'afii10105'       => 331,
        'afii10106'       => 873,
        'afii10107'       => 833,
        'afii10108'       => 582,
        'afii10109'       => 547,
        'afii10110'       => 534,
        'afii10145'       => 655,
        'afii10193'       => 577,
        'afii61248'       => 721,
        'afii61289'       => 585,
        'afii61352'       => 958,
        'agrave'       => 592,
        'alpha'       => 581,
        'alphatonos'       => 581,
        'amacron'       => 592,
        'ampersand'       => 706,
        'anoteleia'       => 367,
        'aogonek'       => 592,
        'apostrophearmenian'       => 367,
        'approxequal'       => 585,
        'aring'       => 592,
        'aringacute'       => 592,
        'asciicircum'       => 585,
        'asciitilde'       => 585,
        'asterisk'       => 432,
        'at'       => 770,
        'atilde'       => 592,
        'aybarmenian'       => 842,
        'b'       => 593,
        'backslash'       => 477,
        'bar'       => 585,
        'benarmenian'       => 568,
        'beta'       => 583,
        'braceleft'       => 485,
        'braceright'       => 485,
        'bracketleft'       => 485,
        'bracketright'       => 485,
        'breve'       => 585,
        'brokenbar'       => 585,
        'bullet'       => 524,
        'c'       => 492,
        'caarmenian'       => 576,
        'cacute'       => 492,
        'caron'       => 585,
        'ccaron'       => 492,
        'ccedilla'       => 492,
        'ccircumflex'       => 492,
        'cdotaccent'       => 492,
        'cedilla'       => 585,
        'cent'       => 585,
        'chaarmenian'       => 387,
        'cheharmenian'       => 578,
        'chi'       => 574,
        'circumflex'       => 585,
        'coarmenian'       => 585,
        'colon'       => 367,
        'comma'       => 367,
        'commaarmenian'       => 258,
        'copyright'       => 712,
        'currency'       => 585,
        'd'       => 593,
        'daarmenian'       => 615,
        'dagger'       => 458,
        'daggerdbl'       => 458,
        'dcaron'       => 706,
        'dcroat'       => 593,
        'degree'       => 585,
        'delta'       => 582,
        'dieresis'       => 585,
        'dieresistonos'       => 585,
        'divide'       => 585,
        'dollar'       => 585,
        'dotaccent'       => 585,
        'dotlessi'       => 326,
        'e'       => 551,
        'eacute'       => 551,
        'ebreve'       => 551,
        'ecaron'       => 551,
        'echarmenian'       => 570,
        'echyiwnarmenian'       => 770,
        'ecircumflex'       => 551,
        'edieresis'       => 551,
        'edotaccent'       => 551,
        'egrave'       => 551,
        'eharmenian'       => 501,
        'eight'       => 585,
        'eightinferior'       => 399,
        'eightsuperior'       => 399,
        'ellipsis'       => 734,
        'emacron'       => 551,
        'emdash'       => 734,
        'emphasismarkarmenian'       => 166,
        'endash'       => 367,
        'eng'       => 562,
        'eogonek'       => 551,
        'epsilon'       => 507,
        'epsilontonos'       => 507,
        'equal'       => 585,
        'estimated'       => 549,
        'eta'       => 586,
        'etarmenian'       => 568,
        'etatonos'       => 586,
        'eth'       => 569,
        'exclam'       => 367,
        'exclamarmenian'       => 224,
        'exclamdbl'       => 611,
        'exclamdown'       => 367,
        'f'       => 410,
        'feharmenian'       => 783,
        'ff'       => 675,
        'ffi'       => 979,
        'ffl'       => 957,
        'fi'       => 668,
        'five'       => 585,
        'fiveeighths'       => 876,
        'fiveinferior'       => 399,
        'fivesuperior'       => 399,
        'fl'       => 644,
        'florin'       => 585,
        'four'       => 585,
        'fourinferior'       => 399,
        'foursuperior'       => 399,
        'fraction'       => 585,
        'franc'       => 882,
        'g'       => 535,
        'gamma'       => 565,
        'gbreve'       => 535,
        'gcircumflex'       => 535,
        'gcommaaccent'       => 535,
        'gdotaccent'       => 535,
        'germandbls'       => 577,
        'ghadarmenian'       => 571,
        'gimarmenian'       => 623,
        'grave'       => 585,
        'greater'       => 585,
        'greaterequal'       => 585,
        'guillemotleft'       => 524,
        'guillemotright'       => 524,
        'guilsinglleft'       => 367,
        'guilsinglright'       => 367,
        'h'       => 562,
        'hbar'       => 562,
        'hcircumflex'       => 562,
        'hoarmenian'       => 562,
        'hungarumlaut'       => 585,
        'hyphen'       => 367,
        'hyphentwo'       => 367,
        'i'       => 326,
        'iacute'       => 326,
        'ibreve'       => 326,
        'icircumflex'       => 326,
        'idieresis'       => 326,
        'igrave'       => 326,
        'ij'       => 629,
        'imacron'       => 326,
        'infinity'       => 585,
        'iniarmenian'       => 559,
        'integral'       => 524,
        'iogonek'       => 326,
        'iota'       => 282,
        'iotadieresis'       => 282,
        'iotadieresistonos'       => 282,
        'iotatonos'       => 282,
        'itilde'       => 326,
        'j'       => 387,
        'jaarmenian'       => 569,
        'jcircumflex'       => 387,
        'jheharmenian'       => 556,
        'k'       => 539,
        'kappa'       => 574,
        'kcommaaccent'       => 539,
        'keharmenian'       => 599,
        'kenarmenian'       => 565,
        'kgreenlandic'       => 574,
        'l'       => 319,
        'lacute'       => 319,
        'lambda'       => 562,
        'lcaron'       => 405,
        'lcommaaccent'       => 319,
        'ldot'       => 446,
        'less'       => 585,
        'lessequal'       => 585,
        'lira'       => 585,
        'liwnarmenian'       => 254,
        'logicalnot'       => 585,
        'longs'       => 351,
        'lozenge'       => 600,
        'lslash'       => 319,
        'm'       => 830,
        'macron'       => 585,
        'menarmenian'       => 575,
        'minus'       => 585,
        'minute'       => 198,
        'mu'       => 557,
        'multiply'       => 585,
        'n'       => 562,
        'nacute'       => 562,
        'napostrophe'       => 654,
        'ncaron'       => 562,
        'ncommaaccent'       => 562,
        'nine'       => 585,
        'nineinferior'       => 399,
        'ninesuperior'       => 399,
        'notequal'       => 585,
        'nowarmenian'       => 569,
        'nsuperior'       => 427,
        'ntilde'       => 562,
        'nu'       => 545,
        'numbersign'       => 585,
        'o'       => 569,
        'oacute'       => 569,
        'obreve'       => 569,
        'ocircumflex'       => 569,
        'odieresis'       => 569,
        'oe'       => 927,
        'ogonek'       => 585,
        'ograve'       => 569,
        'oharmenian'       => 569,
        'ohungarumlaut'       => 569,
        'omacron'       => 569,
        'omega'       => 794,
        'omegatonos'       => 794,
        'omicron'       => 580,
        'omicrontonos'       => 580,
        'one'       => 585,
        'oneeighth'       => 876,
        'onehalf'       => 876,
        'oneinferior'       => 399,
        'onequarter'       => 876,
        'onesuperior'       => 478,
        'openbullet'       => 354,
        'ordfeminine'       => 427,
        'ordmasculine'       => 433,
        'oslash'       => 569,
        'oslashacute'       => 569,
        'otilde'       => 569,
        'overline'       => 524,
        'p'       => 598,
        'paragraph'       => 585,
        'parenleft'       => 367,
        'parenright'       => 367,
        'partialdiff'       => 576,
        'peharmenian'       => 843,
        'percent'       => 732,
        'period'       => 367,
        'periodarmenian'       => 367,
        'periodcentered'       => 367,
        'perthousand'       => 1042,
        'peseta'       => 1171,
        'phi'       => 757,
        'pi'       => 601,
        'piwrarmenian'       => 833,
        'plus'       => 585,
        'plusminus'       => 585,
        'product'       => 636,
        'psi'       => 785,
        'q'       => 598,
        'question'       => 396,
        'questionarmenian'       => 253,
        'questiondown'       => 367,
        'questiongreek'       => 367,
        'quotedbl'       => 390,
        'quotedblbase'       => 585,
        'quotedblleft'       => 585,
        'quotedblright'       => 585,
        'quoteleft'       => 367,
        'quotereversed'       => 367,
        'quoteright'       => 367,
        'quotesinglbase'       => 367,
        'quotesingle'       => 301,
        'r'       => 446,
        'raarmenian'       => 584,
        'racute'       => 446,
        'radical'       => 585,
        'rcaron'       => 446,
        'rcommaaccent'       => 446,
        'registered'       => 712,
        'reharmenian'       => 563,
        'rho'       => 594,
        'ring'       => 585,
        'ringhalfleftarmenian'       => 367,
        's'       => 458,
        'sacute'       => 458,
        'scaron'       => 458,
        'scedilla'       => 458,
        'scircumflex'       => 458,
        'scommaaccent'       => 458,
        'second'       => 374,
        'section'       => 585,
        'seharmenian'       => 565,
        'semicolon'       => 367,
        'seven'       => 585,
        'seveneighths'       => 876,
        'seveninferior'       => 399,
        'sevensuperior'       => 399,
        'shaarmenian'       => 434,
        'sigma'       => 610,
        'sigma1'       => 475,
        'six'       => 585,
        'sixinferior'       => 399,
        'sixsuperior'       => 399,
        'slash'       => 396,
        'space'       => 301,
        'sterling'       => 585,
        'summation'       => 524,
        't'       => 437,
        'tau'       => 470,
        'tbar'       => 437,
        'tcaron'       => 604,
        'tcedilla'       => 437,
        'tcommaaccent'       => 437,
        'theta'       => 599,
        'thorn'       => 598,
        'three'       => 585,
        'threeeighths'       => 876,
        'threeinferior'       => 399,
        'threequarters'       => 876,
        'threesuperior'       => 463,
        'tilde'       => 585,
        'tiwnarmenian'       => 828,
        'toarmenian'       => 742,
        'tonos'       => 585,
        'trademark'       => 644,
        'two'       => 585,
        'twoinferior'       => 399,
        'twosuperior'       => 464,
        'u'       => 557,
        'uacute'       => 557,
        'ubreve'       => 557,
        'ucircumflex'       => 557,
        'udieresis'       => 557,
        'ugrave'       => 557,
        'uhungarumlaut'       => 557,
        'umacron'       => 557,
        'underscore'       => 585,
        'underscoredbl'       => 585,
        'uni040D'       => 696,
        'uni045D'       => 580,
        'uni058A'       => 367,
        'uni058D'       => 912,
        'uni058E'       => 912,
        'uni058F'       => 750,
        'uni20B8'       => 585,
        'uni20B9'       => 585,
        'uni20BA'       => 585,
        'uni20BB'       => 697,
        'uni20BC'       => 761,
        'uni20BD'       => 585,
        'uni20BE'       => 771,
        'uniFB06'       => 801,
        'uniFB13'       => 1145,
        'uniFB14'       => 1145,
        'uniFB15'       => 1134,
        'uniFB16'       => 1140,
        'uniFB17'       => 1426,
        'uogonek'       => 557,
        'upsilon'       => 588,
        'upsilondieresis'       => 588,
        'upsilondieresistonos'       => 588,
        'upsilontonos'       => 588,
        'uring'       => 557,
        'utilde'       => 557,
        'v'       => 552,
        'vewarmenian'       => 570,
        'voarmenian'       => 563,
        'w'       => 773,
        'wacute'       => 773,
        'wcircumflex'       => 773,
        'wdieresis'       => 773,
        'wgrave'       => 773,
        'x'       => 575,
        'xeharmenian'       => 850,
        'xi'       => 494,
        'y'       => 563,
        'yacute'       => 563,
        'ycircumflex'       => 563,
        'ydieresis'       => 563,
        'yen'       => 585,
        'ygrave'       => 563,
        'yiarmenian'       => 238,
        'yiwnarmenian'       => 445,
        'z'       => 532,
        'zaarmenian'       => 585,
        'zacute'       => 532,
        'zcaron'       => 532,
        'zdotaccent'       => 532,
        'zero'       => 585,
        'zeroinferior'       => 399,
        'zerosuperior'       => 399,
        'zeta'       => 477,
        'zhearmenian'       => 618,
    },
    'wxold' => { # HORIZ. WIDTH TABLE
        'space' => '301',                        # C+0x20 # U+0x0020
        'exclam' => '367',                       # C+0x21 # U+0x0021
        'quotedbl' => '390',                     # C+0x22 # U+0x0022
        'numbersign' => '585',                   # C+0x23 # U+0x0023
        'dollar' => '585',                       # C+0x24 # U+0x0024
        'percent' => '732',                      # C+0x25 # U+0x0025
        'ampersand' => '706',                    # C+0x26 # U+0x0026
        'quotesingle' => '301',                  # C+0x27 # U+0x0027
        'parenleft' => '367',                    # C+0x28 # U+0x0028
        'parenright' => '367',                   # C+0x29 # U+0x0029
        'asterisk' => '432',                     # C+0x2A # U+0x002A
        'plus' => '585',                         # C+0x2B # U+0x002B
        'comma' => '367',                        # C+0x2C # U+0x002C
        'hyphen' => '367',                       # C+0x2D # U+0x002D
        'period' => '367',                       # C+0x2E # U+0x002E
        'slash' => '396',                        # C+0x2F # U+0x002F
        'zero' => '585',                         # C+0x30 # U+0x0030
        'one' => '585',                          # C+0x31 # U+0x0031
        'two' => '585',                          # C+0x32 # U+0x0032
        'three' => '585',                        # C+0x33 # U+0x0033
        'four' => '585',                         # C+0x34 # U+0x0034
        'five' => '585',                         # C+0x35 # U+0x0035
        'six' => '585',                          # C+0x36 # U+0x0036
        'seven' => '585',                        # C+0x37 # U+0x0037
        'eight' => '585',                        # C+0x38 # U+0x0038
        'nine' => '585',                         # C+0x39 # U+0x0039
        'colon' => '367',                        # C+0x3A # U+0x003A
        'semicolon' => '367',                    # C+0x3B # U+0x003B
        'less' => '585',                         # C+0x3C # U+0x003C
        'equal' => '585',                        # C+0x3D # U+0x003D
        'greater' => '585',                      # C+0x3E # U+0x003E
        'question' => '396',                     # C+0x3F # U+0x003F
        'at' => '770',                           # C+0x40 # U+0x0040
        'A' => '613',                            # C+0x41 # U+0x0041
        'B' => '589',                            # C+0x42 # U+0x0042
        'C' => '612',                            # C+0x43 # U+0x0043
        'D' => '632',                            # C+0x44 # U+0x0044
        'E' => '593',                            # C+0x45 # U+0x0045
        'F' => '585',                            # C+0x46 # U+0x0046
        'G' => '676',                            # C+0x47 # U+0x0047
        'H' => '678',                            # C+0x48 # U+0x0048
        'I' => '278',                            # C+0x49 # U+0x0049
        'J' => '498',                            # C+0x4A # U+0x004A
        'K' => '649',                            # C+0x4B # U+0x004B
        'L' => '528',                            # C+0x4C # U+0x004C
        'M' => '786',                            # C+0x4D # U+0x004D
        'N' => '660',                            # C+0x4E # U+0x004E
        'O' => '702',                            # C+0x4F # U+0x004F
        'P' => '583',                            # C+0x50 # U+0x0050
        'Q' => '769',                            # C+0x51 # U+0x0051
        'R' => '623',                            # C+0x52 # U+0x0052
        'S' => '501',                            # C+0x53 # U+0x0053
        'T' => '685',                            # C+0x54 # U+0x0054
        'U' => '661',                            # C+0x55 # U+0x0055
        'V' => '683',                            # C+0x56 # U+0x0056
        'W' => '926',                            # C+0x57 # U+0x0057
        'X' => '656',                            # C+0x58 # U+0x0058
        'Y' => '683',                            # C+0x59 # U+0x0059
        'Z' => '611',                            # C+0x5A # U+0x005A
        'bracketleft' => '485',                  # C+0x5B # U+0x005B
        'backslash' => '477',                    # C+0x5C # U+0x005C
        'bracketright' => '485',                 # C+0x5D # U+0x005D
        'asciicircum' => '585',                  # C+0x5E # U+0x005E
        'underscore' => '585',                   # C+0x5F # U+0x005F
        'grave' => '585',                        # C+0x60 # U+0x0060
        'a' => '592',                            # C+0x61 # U+0x0061
        'b' => '593',                            # C+0x62 # U+0x0062
        'c' => '492',                            # C+0x63 # U+0x0063
        'd' => '593',                            # C+0x64 # U+0x0064
        'e' => '551',                            # C+0x65 # U+0x0065
        'f' => '410',                            # C+0x66 # U+0x0066
        'g' => '535',                            # C+0x67 # U+0x0067
        'h' => '562',                            # C+0x68 # U+0x0068
        'i' => '326',                            # C+0x69 # U+0x0069
        'j' => '387',                            # C+0x6A # U+0x006A
        'k' => '539',                            # C+0x6B # U+0x006B
        'l' => '319',                            # C+0x6C # U+0x006C
        'm' => '830',                            # C+0x6D # U+0x006D
        'n' => '562',                            # C+0x6E # U+0x006E
        'o' => '569',                            # C+0x6F # U+0x006F
        'p' => '598',                            # C+0x70 # U+0x0070
        'q' => '598',                            # C+0x71 # U+0x0071
        'r' => '446',                            # C+0x72 # U+0x0072
        's' => '458',                            # C+0x73 # U+0x0073
        't' => '437',                            # C+0x74 # U+0x0074
        'u' => '557',                            # C+0x75 # U+0x0075
        'v' => '552',                            # C+0x76 # U+0x0076
        'w' => '773',                            # C+0x77 # U+0x0077
        'x' => '575',                            # C+0x78 # U+0x0078
        'y' => '563',                            # C+0x79 # U+0x0079
        'z' => '532',                            # C+0x7A # U+0x007A
        'braceleft' => '485',                    # C+0x7B # U+0x007B
        'bar' => '585',                          # C+0x7C # U+0x007C
        'braceright' => '485',                   # C+0x7D # U+0x007D
        'asciitilde' => '585',                   # C+0x7E # U+0x007E
        'bullet' => '524',                       # C+0x7F # U+0x2022
        'Euro' => '585',                         # C+0x80 # U+0x20AC
        'quotesinglbase' => '367',               # C+0x82 # U+0x201A
        'florin' => '585',                       # C+0x83 # U+0x0192
        'quotedblbase' => '585',                 # C+0x84 # U+0x201E
        'ellipsis' => '734',                     # C+0x85 # U+0x2026
        'dagger' => '458',                       # C+0x86 # U+0x2020
        'daggerdbl' => '458',                    # C+0x87 # U+0x2021
        'circumflex' => '585',                   # C+0x88 # U+0x02C6
        'perthousand' => '1042',                 # C+0x89 # U+0x2030
        'Scaron' => '501',                       # C+0x8A # U+0x0160
        'guilsinglleft' => '367',                # C+0x8B # U+0x2039
        'OE' => '1058',                          # C+0x8C # U+0x0152
        'Zcaron' => '611',                       # C+0x8E # U+0x017D
        'quoteleft' => '367',                    # C+0x91 # U+0x2018
        'quoteright' => '367',                   # C+0x92 # U+0x2019
        'quotedblleft' => '585',                 # C+0x93 # U+0x201C
        'quotedblright' => '585',                # C+0x94 # U+0x201D
        'endash' => '367',                       # C+0x96 # U+0x2013
        'emdash' => '734',                       # C+0x97 # U+0x2014
        'tilde' => '585',                        # C+0x98 # U+0x02DC
        'trademark' => '644',                    # C+0x99 # U+0x2122
        'scaron' => '458',                       # C+0x9A # U+0x0161
        'guilsinglright' => '367',               # C+0x9B # U+0x203A
        'oe' => '927',                           # C+0x9C # U+0x0153
        'zcaron' => '532',                       # C+0x9E # U+0x017E
        'Ydieresis' => '683',                    # C+0x9F # U+0x0178
        'exclamdown' => '367',                   # C+0xA1 # U+0x00A1
        'cent' => '585',                         # C+0xA2 # U+0x00A2
        'sterling' => '585',                     # C+0xA3 # U+0x00A3
        'currency' => '585',                     # C+0xA4 # U+0x00A4
        'yen' => '585',                          # C+0xA5 # U+0x00A5
        'brokenbar' => '585',                    # C+0xA6 # U+0x00A6
        'section' => '585',                      # C+0xA7 # U+0x00A7
        'dieresis' => '585',                     # C+0xA8 # U+0x00A8
        'copyright' => '712',                    # C+0xA9 # U+0x00A9
        'ordfeminine' => '427',                  # C+0xAA # U+0x00AA
        'guillemotleft' => '524',                # C+0xAB # U+0x00AB
        'logicalnot' => '585',                   # C+0xAC # U+0x00AC
        'registered' => '712',                   # C+0xAE # U+0x00AE
        'macron' => '585',                       # C+0xAF # U+0x00AF
        'degree' => '585',                       # C+0xB0 # U+0x00B0
        'plusminus' => '585',                    # C+0xB1 # U+0x00B1
        'twosuperior' => '464',                  # C+0xB2 # U+0x00B2
        'threesuperior' => '463',                # C+0xB3 # U+0x00B3
        'acute' => '585',                        # C+0xB4 # U+0x00B4
        'mu' => '557',                           # C+0xB5 # U+0x00B5
        'paragraph' => '585',                    # C+0xB6 # U+0x00B6
        'periodcentered' => '367',               # C+0xB7 # U+0x00B7
        'cedilla' => '585',                      # C+0xB8 # U+0x00B8
        'onesuperior' => '478',                  # C+0xB9 # U+0x00B9
        'ordmasculine' => '433',                 # C+0xBA # U+0x00BA
        'guillemotright' => '524',               # C+0xBB # U+0x00BB
        'onequarter' => '876',                   # C+0xBC # U+0x00BC
        'onehalf' => '876',                      # C+0xBD # U+0x00BD
        'threequarters' => '876',                # C+0xBE # U+0x00BE
        'questiondown' => '367',                 # C+0xBF # U+0x00BF
        'Agrave' => '613',                       # C+0xC0 # U+0x00C0
        'Aacute' => '613',                       # C+0xC1 # U+0x00C1
        'Acircumflex' => '613',                  # C+0xC2 # U+0x00C2
        'Atilde' => '613',                       # C+0xC3 # U+0x00C3
        'Adieresis' => '613',                    # C+0xC4 # U+0x00C4
        'Aring' => '613',                        # C+0xC5 # U+0x00C5
        'AE' => '959',                           # C+0xC6 # U+0x00C6
        'Ccedilla' => '612',                     # C+0xC7 # U+0x00C7
        'Egrave' => '593',                       # C+0xC8 # U+0x00C8
        'Eacute' => '593',                       # C+0xC9 # U+0x00C9
        'Ecircumflex' => '593',                  # C+0xCA # U+0x00CA
        'Edieresis' => '593',                    # C+0xCB # U+0x00CB
        'Igrave' => '278',                       # C+0xCC # U+0x00CC
        'Iacute' => '278',                       # C+0xCD # U+0x00CD
        'Icircumflex' => '278',                  # C+0xCE # U+0x00CE
        'Idieresis' => '278',                    # C+0xCF # U+0x00CF
        'Eth' => '654',                          # C+0xD0 # U+0x00D0
        'Ntilde' => '660',                       # C+0xD1 # U+0x00D1
        'Ograve' => '702',                       # C+0xD2 # U+0x00D2
        'Oacute' => '702',                       # C+0xD3 # U+0x00D3
        'Ocircumflex' => '702',                  # C+0xD4 # U+0x00D4
        'Otilde' => '702',                       # C+0xD5 # U+0x00D5
        'Odieresis' => '702',                    # C+0xD6 # U+0x00D6
        'multiply' => '585',                     # C+0xD7 # U+0x00D7
        'Oslash' => '702',                       # C+0xD8 # U+0x00D8
        'Ugrave' => '661',                       # C+0xD9 # U+0x00D9
        'Uacute' => '661',                       # C+0xDA # U+0x00DA
        'Ucircumflex' => '661',                  # C+0xDB # U+0x00DB
        'Udieresis' => '661',                    # C+0xDC # U+0x00DC
        'Yacute' => '683',                       # C+0xDD # U+0x00DD
        'Thorn' => '561',                        # C+0xDE # U+0x00DE
        'germandbls' => '577',                   # C+0xDF # U+0x00DF
        'agrave' => '592',                       # C+0xE0 # U+0x00E0
        'aacute' => '592',                       # C+0xE1 # U+0x00E1
        'acircumflex' => '592',                  # C+0xE2 # U+0x00E2
        'atilde' => '592',                       # C+0xE3 # U+0x00E3
        'adieresis' => '592',                    # C+0xE4 # U+0x00E4
        'aring' => '592',                        # C+0xE5 # U+0x00E5
        'ae' => '893',                           # C+0xE6 # U+0x00E6
        'ccedilla' => '492',                     # C+0xE7 # U+0x00E7
        'egrave' => '551',                       # C+0xE8 # U+0x00E8
        'eacute' => '551',                       # C+0xE9 # U+0x00E9
        'ecircumflex' => '551',                  # C+0xEA # U+0x00EA
        'edieresis' => '551',                    # C+0xEB # U+0x00EB
        'igrave' => '326',                       # C+0xEC # U+0x00EC
        'iacute' => '326',                       # C+0xED # U+0x00ED
        'icircumflex' => '326',                  # C+0xEE # U+0x00EE
        'idieresis' => '326',                    # C+0xEF # U+0x00EF
        'eth' => '569',                          # C+0xF0 # U+0x00F0
        'ntilde' => '562',                       # C+0xF1 # U+0x00F1
        'ograve' => '569',                       # C+0xF2 # U+0x00F2
        'oacute' => '569',                       # C+0xF3 # U+0x00F3
        'ocircumflex' => '569',                  # C+0xF4 # U+0x00F4
        'otilde' => '569',                       # C+0xF5 # U+0x00F5
        'odieresis' => '569',                    # C+0xF6 # U+0x00F6
        'divide' => '585',                       # C+0xF7 # U+0x00F7
        'oslash' => '569',                       # C+0xF8 # U+0x00F8
        'ugrave' => '557',                       # C+0xF9 # U+0x00F9
        'uacute' => '557',                       # C+0xFA # U+0x00FA
        'ucircumflex' => '557',                  # C+0xFB # U+0x00FB
        'udieresis' => '557',                    # C+0xFC # U+0x00FC
        'yacute' => '563',                       # C+0xFD # U+0x00FD
        'thorn' => '598',                        # C+0xFE # U+0x00FE
        'ydieresis' => '563',                    # C+0xFF # U+0x00FF
        'middot' => '367',                       # U+0x00B7
        'Amacron' => '613',                      # U+0x0100
        'amacron' => '592',                      # U+0x0101
        'Abreve' => '613',                       # U+0x0102
        'abreve' => '592',                       # U+0x0103
        'Aogonek' => '613',                      # U+0x0104
        'aogonek' => '592',                      # U+0x0105
        'Cacute' => '612',                       # U+0x0106
        'cacute' => '492',                       # U+0x0107
        'Ccircumflex' => '612',                  # U+0x0108
        'ccircumflex' => '492',                  # U+0x0109
        'Cdot' => '612',                         # U+0x010A
        'cdot' => '492',                         # U+0x010B
        'Ccaron' => '612',                       # U+0x010C
        'ccaron' => '492',                       # U+0x010D
        'Dcaron' => '632',                       # U+0x010E
        'dcaron' => '706',                       # U+0x010F
        'dcroat' => '593',                       # U+0x0111
        'Emacron' => '593',                      # U+0x0112
        'emacron' => '551',                      # U+0x0113
        'Ebreve' => '593',                       # U+0x0114
        'ebreve' => '551',                       # U+0x0115
        'Edot' => '593',                         # U+0x0116
        'edot' => '551',                         # U+0x0117
        'Eogonek' => '593',                      # U+0x0118
        'eogonek' => '551',                      # U+0x0119
        'Ecaron' => '593',                       # U+0x011A
        'ecaron' => '551',                       # U+0x011B
        'Gcircumflex' => '676',                  # U+0x011C
        'gcircumflex' => '535',                  # U+0x011D
        'Gbreve' => '676',                       # U+0x011E
        'gbreve' => '535',                       # U+0x011F
        'Gdot' => '676',                         # U+0x0120
        'gdot' => '535',                         # U+0x0121
        'Hcircumflex' => '678',                  # U+0x0124
        'hcircumflex' => '562',                  # U+0x0125
        'Hbar' => '699',                         # U+0x0126
        'hbar' => '562',                         # U+0x0127
        'Itilde' => '278',                       # U+0x0128
        'itilde' => '326',                       # U+0x0129
        'Imacron' => '278',                      # U+0x012A
        'imacron' => '326',                      # U+0x012B
        'Ibreve' => '278',                       # U+0x012C
        'ibreve' => '326',                       # U+0x012D
        'Iogonek' => '278',                      # U+0x012E
        'iogonek' => '326',                      # U+0x012F
        'Idotaccent' => '278',                   # U+0x0130
        'dotlessi' => '326',                     # U+0x0131
        'IJ' => '756',                           # U+0x0132
        'ij' => '629',                           # U+0x0133
        'Jcircumflex' => '498',                  # U+0x0134
        'jcircumflex' => '387',                  # U+0x0135
        'kgreenlandic' => '574',                 # U+0x0138
        'Lacute' => '528',                       # U+0x0139
        'lacute' => '319',                       # U+0x013A
        'Lcaron' => '528',                       # U+0x013D
        'lcaron' => '405',                       # U+0x013E
        'Ldot' => '528',                         # U+0x013F
        'ldot' => '446',                         # U+0x0140
        'Lslash' => '528',                       # U+0x0141
        'lslash' => '319',                       # U+0x0142
        'Nacute' => '660',                       # U+0x0143
        'nacute' => '562',                       # U+0x0144
        'Ncaron' => '660',                       # U+0x0147
        'ncaron' => '562',                       # U+0x0148
        'napostrophe' => '654',                  # U+0x0149
        'Eng' => '672',                          # U+0x014A
        'eng' => '562',                          # U+0x014B
        'Omacron' => '702',                      # U+0x014C
        'omacron' => '569',                      # U+0x014D
        'Obreve' => '702',                       # U+0x014E
        'obreve' => '569',                       # U+0x014F
        'Racute' => '623',                       # U+0x0154
        'racute' => '446',                       # U+0x0155
        'Rcaron' => '623',                       # U+0x0158
        'rcaron' => '446',                       # U+0x0159
        'Sacute' => '501',                       # U+0x015A
        'sacute' => '458',                       # U+0x015B
        'Scircumflex' => '501',                  # U+0x015C
        'scircumflex' => '458',                  # U+0x015D
        'Scedilla' => '501',                     # U+0x015E
        'scedilla' => '458',                     # U+0x015F
        'Tcaron' => '685',                       # U+0x0164
        'tcaron' => '604',                       # U+0x0165
        'Tbar' => '685',                         # U+0x0166
        'tbar' => '437',                         # U+0x0167
        'Utilde' => '661',                       # U+0x0168
        'utilde' => '557',                       # U+0x0169
        'Umacron' => '661',                      # U+0x016A
        'umacron' => '557',                      # U+0x016B
        'Ubreve' => '661',                       # U+0x016C
        'ubreve' => '557',                       # U+0x016D
        'Uring' => '661',                        # U+0x016E
        'uring' => '557',                        # U+0x016F
        'Uogonek' => '661',                      # U+0x0172
        'uogonek' => '557',                      # U+0x0173
        'Wcircumflex' => '926',                  # U+0x0174
        'wcircumflex' => '773',                  # U+0x0175
        'Ycircumflex' => '683',                  # U+0x0176
        'ycircumflex' => '563',                  # U+0x0177
        'Zacute' => '611',                       # U+0x0179
        'zacute' => '532',                       # U+0x017A
        'Zdot' => '611',                         # U+0x017B
        'zdot' => '532',                         # U+0x017C
        'caron' => '585',                        # U+0x02C7
        'breve' => '585',                        # U+0x02D8
        'dotaccent' => '585',                    # U+0x02D9
        'ring' => '585',                         # U+0x02DA
        'ogonek' => '585',                       # U+0x02DB
        'hungarumlaut' => '585',                 # U+0x02DD
        'dblgravecmb' => '585',                  # U+0x030F
        'Delta' => '584',                        # U+0x0394
        'Omega' => '668',                        # U+0x03A9
        'pi' => '601',                           # U+0x03C0
        'fraction' => '585',                     # U+0x2044
        'franc' => '882',                        # U+0x20A3
        'partialdiff' => '576',                  # U+0x2202
        'product' => '636',                      # U+0x220F
        'summation' => '524',                    # U+0x2211
        'minus' => '585',                        # U+0x2212
        'radical' => '585',                      # U+0x221A
        'infinity' => '585',                     # U+0x221E
        'integral' => '524',                     # U+0x222B
        'approxequal' => '585',                  # U+0x2248
        'notequal' => '585',                     # U+0x2260
        'lessequal' => '585',                    # U+0x2264
        'greaterequal' => '585',                 # U+0x2265
        'lozenge' => '600',                      # U+0x25CA
        'dotlessj' => '387',                     # U+0xF6BE
        'fi' => '668',                           # U+0xFB01
        'fl' => '644',                           # U+0xFB02
    }, # HORIZ. WIDTH TABLE
} };

1;
