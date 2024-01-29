package PDF::Builder::Resource::Font::CoreFont::trebuchetbold;

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.018'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::Font::CoreFont::trebuchetbold - font-specific information for bold-weight Trebuchet font
(I<not> standard PDF core)

=cut

sub data { return {
    'fontname' => 'TrebuchetMS,Bold',
    'type' => 'TrueType',
    'apiname' => 'TrBo',
    'ascender' => '938',
    'capheight' => '715',
    'descender' => '-222',
    'isfixedpitch' => '0',
    'issymbol' => '0',
    'italicangle' => '0',
    'underlineposition' => '-261',
    'underlinethickness' => '200',
    'xheight' => '522',
    'firstchar' => '32',
    'lastchar' => '255',
    'flags' => '262178',
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
    'fontbbox' => [ -100, -269, 1129, 980 ],
# source: \Windows\Fonts\trebucbd.ttf
# font underline position = -261
# CIDs 0 .. 1178 to be output
# fontbbox = (-582 -269 1386 980)
    'wx' => { # HORIZ. WIDTH TABLE
        'A'       => 633,
        'AE'       => 935,
        'AEacute'       => 935,
        'Aacute'       => 633,
        'Abreve'       => 633,
        'Acircumflex'       => 633,
        'Adieresis'       => 633,
        'Agrave'       => 633,
        'Alpha'       => 632,
        'Alphatonos'       => 643,
        'Amacron'       => 633,
        'Aogonek'       => 633,
        'Aring'       => 633,
        'Aringacute'       => 633,
        'Atilde'       => 633,
        'Aybarmenian'       => 697,
        'B'       => 595,
        'Benarmenian'       => 677,
        'Beta'       => 595,
        'C'       => 611,
        'Caarmenian'       => 703,
        'Cacute'       => 611,
        'Ccaron'       => 611,
        'Ccedilla'       => 611,
        'Ccircumflex'       => 611,
        'Cdotaccent'       => 611,
        'Chaarmenian'       => 663,
        'Cheharmenian'       => 716,
        'Chi'       => 601,
        'Coarmenian'       => 661,
        'D'       => 642,
        'Daarmenian'       => 672,
        'Dcaron'       => 642,
        'Dcroat'       => 642,
        'Delta'       => 584,
        'E'       => 568,
        'Eacute'       => 568,
        'Ebreve'       => 568,
        'Ecaron'       => 568,
        'Echarmenian'       => 667,
        'Ecircumflex'       => 568,
        'Edieresis'       => 568,
        'Edotaccent'       => 568,
        'Egrave'       => 568,
        'Eharmenian'       => 584,
        'Emacron'       => 568,
        'Eng'       => 682,
        'Eogonek'       => 568,
        'Epsilon'       => 568,
        'Epsilontonos'       => 688,
        'Eta'       => 684,
        'Etarmenian'       => 677,
        'Etatonos'       => 804,
        'Eth'       => 642,
        'Euro'       => 585,
        'F'       => 583,
        'Feharmenian'       => 789,
        'G'       => 671,
        'Gamma'       => 544,
        'Gbreve'       => 671,
        'Gcircumflex'       => 671,
        'Gcommaaccent'       => 671,
        'Gdotaccent'       => 671,
        'Ghadarmenian'       => 672,
        'Gimarmenian'       => 693,
        'H'       => 683,
        'H18533'       => 604,
        'H18543'       => 354,
        'H18551'       => 354,
        'H22073'       => 604,
        'Hbar'       => 701,
        'Hcircumflex'       => 683,
        'Hoarmenian'       => 602,
        'I'       => 278,
        'IJ'       => 791,
        'Iacute'       => 278,
        'Ibreve'       => 278,
        'Icircumflex'       => 278,
        'Idieresis'       => 278,
        'Idotaccent'       => 278,
        'Igrave'       => 278,
        'Imacron'       => 278,
        'Iniarmenian'       => 643,
        'Iogonek'       => 278,
        'Iota'       => 277,
        'Iotadieresis'       => 277,
        'Iotatonos'       => 395,
        'Itilde'       => 278,
        'J'       => 532,
        'Jaarmenian'       => 713,
        'Jcircumflex'       => 532,
        'Jheharmenian'       => 708,
        'K'       => 617,
        'Kappa'       => 617,
        'Kcommaaccent'       => 617,
        'Keharmenian'       => 692,
        'Kenarmenian'       => 667,
        'L'       => 552,
        'Lacute'       => 552,
        'Lambda'       => 628,
        'Lcaron'       => 552,
        'Lcommaaccent'       => 552,
        'Ldot'       => 552,
        'Liwnarmenian'       => 552,
        'Lslash'       => 552,
        'M'       => 745,
        'Menarmenian'       => 711,
        'Mu'       => 745,
        'N'       => 667,
        'Nacute'       => 667,
        'Ncaron'       => 667,
        'Ncommaaccent'       => 667,
        'Nowarmenian'       => 682,
        'Ntilde'       => 667,
        'Nu'       => 666,
        'O'       => 703,
        'OE'       => 1003,
        'Oacute'       => 703,
        'Obreve'       => 703,
        'Ocircumflex'       => 703,
        'Odieresis'       => 703,
        'Ograve'       => 703,
        'Oharmenian'       => 703,
        'Ohungarumlaut'       => 703,
        'Omacron'       => 703,
        'Omega'       => 668,
        'Omegatonos'       => 793,
        'Omicron'       => 703,
        'Omicrontonos'       => 770,
        'Oslash'       => 683,
        'Oslashacute'       => 683,
        'Otilde'       => 703,
        'P'       => 586,
        'Peharmenian'       => 812,
        'Phi'       => 794,
        'Pi'       => 664,
        'Piwrarmenian'       => 845,
        'Psi'       => 813,
        'Q'       => 708,
        'R'       => 610,
        'Raarmenian'       => 711,
        'Racute'       => 610,
        'Rcaron'       => 610,
        'Rcommaaccent'       => 610,
        'Reharmenian'       => 638,
        'Rho'       => 586,
        'S'       => 511,
        'Sacute'       => 511,
        'Scaron'       => 511,
        'Scedilla'       => 511,
        'Scircumflex'       => 511,
        'Scommaaccent'       => 511,
        'Seharmenian'       => 677,
        'Shaarmenian'       => 672,
        'Sigma'       => 582,
        'T'       => 611,
        'Tau'       => 611,
        'Tbar'       => 611,
        'Tcaron'       => 611,
        'Tcedilla'       => 611,
        'Tcommaaccent'       => 611,
        'Theta'       => 717,
        'Thorn'       => 557,
        'Tiwnarmenian'       => 662,
        'Toarmenian'       => 872,
        'U'       => 677,
        'Uacute'       => 677,
        'Ubreve'       => 677,
        'Ucircumflex'       => 677,
        'Udieresis'       => 677,
        'Ugrave'       => 677,
        'Uhungarumlaut'       => 677,
        'Umacron'       => 677,
        'Uogonek'       => 677,
        'Upsilon'       => 612,
        'Upsilondieresis'       => 612,
        'Upsilontonos'       => 774,
        'Uring'       => 677,
        'Utilde'       => 677,
        'V'       => 621,
        'Vewarmenian'       => 672,
        'Voarmenian'       => 677,
        'W'       => 883,
        'Wacute'       => 883,
        'Wcircumflex'       => 883,
        'Wdieresis'       => 883,
        'Wgrave'       => 883,
        'X'       => 600,
        'Xeharmenian'       => 880,
        'Xi'       => 630,
        'Y'       => 613,
        'Yacute'       => 613,
        'Ycircumflex'       => 613,
        'Ydieresis'       => 613,
        'Ygrave'       => 613,
        'Yiarmenian'       => 658,
        'Yiwnarmenian'       => 514,
        'Z'       => 560,
        'Zaarmenian'       => 707,
        'Zacute'       => 560,
        'Zcaron'       => 560,
        'Zdotaccent'       => 560,
        'Zeta'       => 560,
        'Zhearmenian'       => 693,
        'a'       => 532,
        'aacute'       => 532,
        'abbreviationmarkarmenian'       => 0,
        'abreve'       => 532,
        'acircumflex'       => 532,
        'acute'       => 585,
        'adieresis'       => 532,
        'ae'       => 862,
        'aeacute'       => 862,
        'afii00208'       => 734,
        'afii10017'       => 637,
        'afii10018'       => 598,
        'afii10019'       => 597,
        'afii10020'       => 549,
        'afii10021'       => 729,
        'afii10022'       => 576,
        'afii10023'       => 576,
        'afii10024'       => 933,
        'afii10025'       => 557,
        'afii10026'       => 702,
        'afii10027'       => 719,
        'afii10028'       => 640,
        'afii10029'       => 698,
        'afii10030'       => 777,
        'afii10031'       => 684,
        'afii10032'       => 703,
        'afii10033'       => 665,
        'afii10034'       => 588,
        'afii10035'       => 611,
        'afii10036'       => 649,
        'afii10037'       => 621,
        'afii10038'       => 790,
        'afii10039'       => 611,
        'afii10040'       => 680,
        'afii10041'       => 632,
        'afii10042'       => 930,
        'afii10043'       => 958,
        'afii10044'       => 775,
        'afii10045'       => 838,
        'afii10046'       => 605,
        'afii10047'       => 617,
        'afii10048'       => 941,
        'afii10049'       => 640,
        'afii10050'       => 549,
        'afii10051'       => 754,
        'afii10052'       => 549,
        'afii10053'       => 611,
        'afii10054'       => 513,
        'afii10055'       => 277,
        'afii10056'       => 277,
        'afii10057'       => 545,
        'afii10058'       => 1005,
        'afii10059'       => 949,
        'afii10060'       => 768,
        'afii10061'       => 640,
        'afii10062'       => 621,
        'afii10065'       => 534,
        'afii10066'       => 583,
        'afii10067'       => 544,
        'afii10068'       => 461,
        'afii10069'       => 625,
        'afii10070'       => 578,
        'afii10071'       => 578,
        'afii10072'       => 778,
        'afii10073'       => 482,
        'afii10074'       => 601,
        'afii10075'       => 601,
        'afii10076'       => 545,
        'afii10077'       => 599,
        'afii10078'       => 720,
        'afii10079'       => 592,
        'afii10080'       => 569,
        'afii10081'       => 583,
        'afii10082'       => 584,
        'afii10083'       => 516,
        'afii10084'       => 486,
        'afii10085'       => 541,
        'afii10086'       => 796,
        'afii10087'       => 560,
        'afii10088'       => 602,
        'afii10089'       => 566,
        'afii10090'       => 794,
        'afii10091'       => 821,
        'afii10092'       => 650,
        'afii10093'       => 746,
        'afii10094'       => 540,
        'afii10095'       => 523,
        'afii10096'       => 764,
        'afii10097'       => 560,
        'afii10098'       => 458,
        'afii10099'       => 599,
        'afii10100'       => 461,
        'afii10101'       => 523,
        'afii10102'       => 436,
        'afii10103'       => 300,
        'afii10104'       => 300,
        'afii10105'       => 332,
        'afii10106'       => 871,
        'afii10107'       => 839,
        'afii10108'       => 599,
        'afii10109'       => 545,
        'afii10110'       => 541,
        'afii10145'       => 634,
        'afii10193'       => 589,
        'afii61248'       => 786,
        'afii61289'       => 585,
        'afii61352'       => 965,
        'agrave'       => 532,
        'alpha'       => 594,
        'alphatonos'       => 594,
        'amacron'       => 532,
        'ampersand'       => 706,
        'anoteleia'       => 367,
        'aogonek'       => 532,
        'apostrophearmenian'       => 367,
        'approxequal'       => 585,
        'aring'       => 532,
        'aringacute'       => 532,
        'asciicircum'       => 585,
        'asciitilde'       => 585,
        'asterisk'       => 432,
        'at'       => 770,
        'atilde'       => 532,
        'aybarmenian'       => 859,
        'b'       => 581,
        'backslash'       => 355,
        'bar'       => 585,
        'benarmenian'       => 597,
        'beta'       => 585,
        'braceleft'       => 433,
        'braceright'       => 433,
        'bracketleft'       => 401,
        'bracketright'       => 401,
        'breve'       => 585,
        'brokenbar'       => 585,
        'bullet'       => 524,
        'c'       => 511,
        'caarmenian'       => 576,
        'cacute'       => 511,
        'caron'       => 585,
        'ccaron'       => 511,
        'ccedilla'       => 511,
        'ccircumflex'       => 511,
        'cdotaccent'       => 511,
        'cedilla'       => 585,
        'cent'       => 585,
        'chaarmenian'       => 384,
        'cheharmenian'       => 587,
        'chi'       => 557,
        'circumflex'       => 585,
        'coarmenian'       => 595,
        'colon'       => 367,
        'comma'       => 367,
        'commaarmenian'       => 259,
        'copyright'       => 712,
        'currency'       => 585,
        'd'       => 580,
        'daarmenian'       => 653,
        'dagger'       => 458,
        'daggerdbl'       => 458,
        'dcaron'       => 733,
        'dcroat'       => 580,
        'degree'       => 585,
        'delta'       => 571,
        'dieresis'       => 585,
        'dieresistonos'       => 585,
        'divide'       => 585,
        'dollar'       => 585,
        'dotaccent'       => 585,
        'dotlessi'       => 298,
        'e'       => 574,
        'eacute'       => 574,
        'ebreve'       => 574,
        'ecaron'       => 574,
        'echarmenian'       => 592,
        'echyiwnarmenian'       => 798,
        'ecircumflex'       => 574,
        'edieresis'       => 574,
        'edotaccent'       => 574,
        'egrave'       => 574,
        'eharmenian'       => 517,
        'eight'       => 585,
        'eightinferior'       => 399,
        'eightsuperior'       => 399,
        'ellipsis'       => 734,
        'emacron'       => 574,
        'emdash'       => 734,
        'emphasismarkarmenian'       => 166,
        'endash'       => 367,
        'eng'       => 590,
        'eogonek'       => 574,
        'epsilon'       => 507,
        'epsilontonos'       => 507,
        'equal'       => 585,
        'estimated'       => 549,
        'eta'       => 590,
        'etarmenian'       => 595,
        'etatonos'       => 590,
        'eth'       => 565,
        'exclam'       => 367,
        'exclamarmenian'       => 224,
        'exclamdbl'       => 609,
        'exclamdown'       => 367,
        'f'       => 369,
        'feharmenian'       => 794,
        'ff'       => 669,
        'ffi'       => 938,
        'ffl'       => 946,
        'fi'       => 622,
        'five'       => 585,
        'fiveeighths'       => 814,
        'fiveinferior'       => 399,
        'fivesuperior'       => 399,
        'fl'       => 636,
        'florin'       => 388,
        'four'       => 585,
        'fourinferior'       => 399,
        'foursuperior'       => 399,
        'fraction'       => 585,
        'franc'       => 583,
        'g'       => 501,
        'gamma'       => 566,
        'gbreve'       => 501,
        'gcircumflex'       => 501,
        'gcommaaccent'       => 501,
        'gdotaccent'       => 501,
        'germandbls'       => 546,
        'ghadarmenian'       => 595,
        'gimarmenian'       => 652,
        'grave'       => 585,
        'greater'       => 585,
        'greaterequal'       => 585,
        'guillemotleft'       => 585,
        'guillemotright'       => 585,
        'guilsinglleft'       => 367,
        'guilsinglright'       => 367,
        'h'       => 592,
        'hbar'       => 599,
        'hcircumflex'       => 592,
        'hoarmenian'       => 592,
        'hungarumlaut'       => 585,
        'hyphen'       => 367,
        'hyphentwo'       => 367,
        'i'       => 298,
        'iacute'       => 298,
        'ibreve'       => 298,
        'icircumflex'       => 298,
        'idieresis'       => 298,
        'igrave'       => 298,
        'ij'       => 622,
        'imacron'       => 298,
        'infinity'       => 585,
        'iniarmenian'       => 590,
        'integral'       => 524,
        'iogonek'       => 298,
        'iota'       => 290,
        'iotadieresis'       => 290,
        'iotadieresistonos'       => 290,
        'iotatonos'       => 290,
        'itilde'       => 298,
        'j'       => 366,
        'jaarmenian'       => 571,
        'jcircumflex'       => 366,
        'jheharmenian'       => 565,
        'k'       => 547,
        'kappa'       => 574,
        'kcommaaccent'       => 547,
        'keharmenian'       => 606,
        'kenarmenian'       => 592,
        'kgreenlandic'       => 574,
        'l'       => 294,
        'lacute'       => 294,
        'lambda'       => 559,
        'lcaron'       => 377,
        'lcommaaccent'       => 294,
        'ldot'       => 436,
        'less'       => 585,
        'lessequal'       => 585,
        'lira'       => 523,
        'liwnarmenian'       => 263,
        'logicalnot'       => 585,
        'longs'       => 360,
        'lozenge'       => 600,
        'lslash'       => 294,
        'm'       => 859,
        'macron'       => 585,
        'menarmenian'       => 590,
        'minus'       => 585,
        'minute'       => 198,
        'mu'       => 546,
        'multiply'       => 585,
        'n'       => 590,
        'nacute'       => 590,
        'napostrophe'       => 683,
        'ncaron'       => 590,
        'ncommaaccent'       => 590,
        'nine'       => 585,
        'nineinferior'       => 399,
        'ninesuperior'       => 399,
        'notequal'       => 585,
        'nowarmenian'       => 592,
        'nsuperior'       => 405,
        'ntilde'       => 590,
        'nu'       => 533,
        'numbersign'       => 585,
        'o'       => 565,
        'oacute'       => 565,
        'obreve'       => 565,
        'ocircumflex'       => 565,
        'odieresis'       => 565,
        'oe'       => 920,
        'ogonek'       => 585,
        'ograve'       => 565,
        'oharmenian'       => 565,
        'ohungarumlaut'       => 565,
        'omacron'       => 565,
        'omega'       => 783,
        'omegatonos'       => 783,
        'omicron'       => 571,
        'omicrontonos'       => 571,
        'one'       => 585,
        'oneeighth'       => 814,
        'onehalf'       => 814,
        'oneinferior'       => 399,
        'onequarter'       => 814,
        'onesuperior'       => 451,
        'openbullet'       => 354,
        'ordfeminine'       => 429,
        'ordmasculine'       => 429,
        'oslash'       => 565,
        'oslashacute'       => 565,
        'otilde'       => 565,
        'overline'       => 524,
        'p'       => 582,
        'paragraph'       => 524,
        'parenleft'       => 367,
        'parenright'       => 367,
        'partialdiff'       => 585,
        'peharmenian'       => 861,
        'percent'       => 684,
        'period'       => 367,
        'periodarmenian'       => 367,
        'periodcentered'       => 367,
        'perthousand'       => 1035,
        'peseta'       => 1162,
        'phi'       => 751,
        'pi'       => 601,
        'piwrarmenian'       => 854,
        'plus'       => 585,
        'plusminus'       => 585,
        'product'       => 636,
        'psi'       => 772,
        'q'       => 583,
        'question'       => 437,
        'questionarmenian'       => 253,
        'questiondown'       => 437,
        'questiongreek'       => 367,
        'quotedbl'       => 366,
        'quotedblbase'       => 524,
        'quotedblleft'       => 585,
        'quotedblright'       => 585,
        'quoteleft'       => 367,
        'quotereversed'       => 367,
        'quoteright'       => 367,
        'quotesinglbase'       => 367,
        'quotesingle'       => 229,
        'r'       => 427,
        'raarmenian'       => 600,
        'racute'       => 427,
        'radical'       => 585,
        'rcaron'       => 427,
        'rcommaaccent'       => 427,
        'registered'       => 712,
        'reharmenian'       => 590,
        'rho'       => 590,
        'ring'       => 585,
        'ringhalfleftarmenian'       => 367,
        's'       => 430,
        'sacute'       => 430,
        'scaron'       => 430,
        'scedilla'       => 430,
        'scircumflex'       => 430,
        'scommaaccent'       => 430,
        'second'       => 374,
        'section'       => 453,
        'seharmenian'       => 590,
        'semicolon'       => 367,
        'seven'       => 585,
        'seveneighths'       => 814,
        'seveninferior'       => 399,
        'sevensuperior'       => 399,
        'shaarmenian'       => 406,
        'sigma'       => 597,
        'sigma1'       => 479,
        'six'       => 585,
        'sixinferior'       => 399,
        'sixsuperior'       => 399,
        'slash'       => 390,
        'space'       => 301,
        'sterling'       => 524,
        'summation'       => 524,
        't'       => 396,
        'tau'       => 471,
        'tbar'       => 396,
        'tcaron'       => 545,
        'tcedilla'       => 396,
        'tcommaaccent'       => 396,
        'theta'       => 577,
        'thorn'       => 582,
        'three'       => 585,
        'threeeighths'       => 814,
        'threeinferior'       => 399,
        'threequarters'       => 814,
        'threesuperior'       => 453,
        'tilde'       => 585,
        'tiwnarmenian'       => 859,
        'toarmenian'       => 744,
        'tonos'       => 585,
        'trademark'       => 644,
        'two'       => 585,
        'twoinferior'       => 399,
        'twosuperior'       => 451,
        'u'       => 590,
        'uacute'       => 590,
        'ubreve'       => 590,
        'ucircumflex'       => 590,
        'udieresis'       => 590,
        'ugrave'       => 590,
        'uhungarumlaut'       => 590,
        'umacron'       => 590,
        'underscore'       => 585,
        'underscoredbl'       => 585,
        'uni040D'       => 702,
        'uni045D'       => 601,
        'uni058A'       => 367,
        'uni058D'       => 912,
        'uni058E'       => 912,
        'uni058F'       => 707,
        'uni20B8'       => 585,
        'uni20B9'       => 585,
        'uni20BA'       => 585,
        'uni20BB'       => 697,
        'uni20BC'       => 761,
        'uni20BD'       => 585,
        'uni20BE'       => 771,
        'uniFB06'       => 818,
        'uniFB13'       => 1183,
        'uniFB14'       => 1183,
        'uniFB15'       => 1180,
        'uniFB16'       => 1185,
        'uniFB17'       => 1454,
        'uogonek'       => 590,
        'upsilon'       => 578,
        'upsilondieresis'       => 578,
        'upsilondieresistonos'       => 578,
        'upsilontonos'       => 578,
        'uring'       => 590,
        'utilde'       => 590,
        'v'       => 527,
        'vewarmenian'       => 592,
        'voarmenian'       => 590,
        'w'       => 783,
        'wacute'       => 783,
        'wcircumflex'       => 783,
        'wdieresis'       => 783,
        'wgrave'       => 783,
        'x'       => 552,
        'xeharmenian'       => 864,
        'xi'       => 481,
        'y'       => 533,
        'yacute'       => 533,
        'ycircumflex'       => 533,
        'ydieresis'       => 533,
        'yen'       => 570,
        'ygrave'       => 533,
        'yiarmenian'       => 258,
        'yiwnarmenian'       => 464,
        'z'       => 528,
        'zaarmenian'       => 598,
        'zacute'       => 528,
        'zcaron'       => 528,
        'zdotaccent'       => 528,
        'zero'       => 585,
        'zeroinferior'       => 399,
        'zerosuperior'       => 399,
        'zeta'       => 465,
        'zhearmenian'       => 630,
    },
    'wxold' => { # HORIZ. WIDTH TABLE
        'space' => '301',                        # C+0x20 # U+0x0020
        'exclam' => '367',                       # C+0x21 # U+0x0021
        'quotedbl' => '366',                     # C+0x22 # U+0x0022
        'numbersign' => '585',                   # C+0x23 # U+0x0023
        'dollar' => '585',                       # C+0x24 # U+0x0024
        'percent' => '684',                      # C+0x25 # U+0x0025
        'ampersand' => '706',                    # C+0x26 # U+0x0026
        'quotesingle' => '229',                  # C+0x27 # U+0x0027
        'parenleft' => '367',                    # C+0x28 # U+0x0028
        'parenright' => '367',                   # C+0x29 # U+0x0029
        'asterisk' => '432',                     # C+0x2A # U+0x002A
        'plus' => '585',                         # C+0x2B # U+0x002B
        'comma' => '367',                        # C+0x2C # U+0x002C
        'hyphen' => '367',                       # C+0x2D # U+0x002D
        'period' => '367',                       # C+0x2E # U+0x002E
        'slash' => '390',                        # C+0x2F # U+0x002F
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
        'question' => '437',                     # C+0x3F # U+0x003F
        'at' => '770',                           # C+0x40 # U+0x0040
        'A' => '633',                            # C+0x41 # U+0x0041
        'B' => '595',                            # C+0x42 # U+0x0042
        'C' => '611',                            # C+0x43 # U+0x0043
        'D' => '642',                            # C+0x44 # U+0x0044
        'E' => '568',                            # C+0x45 # U+0x0045
        'F' => '583',                            # C+0x46 # U+0x0046
        'G' => '671',                            # C+0x47 # U+0x0047
        'H' => '683',                            # C+0x48 # U+0x0048
        'I' => '278',                            # C+0x49 # U+0x0049
        'J' => '532',                            # C+0x4A # U+0x004A
        'K' => '617',                            # C+0x4B # U+0x004B
        'L' => '552',                            # C+0x4C # U+0x004C
        'M' => '745',                            # C+0x4D # U+0x004D
        'N' => '667',                            # C+0x4E # U+0x004E
        'O' => '703',                            # C+0x4F # U+0x004F
        'P' => '586',                            # C+0x50 # U+0x0050
        'Q' => '708',                            # C+0x51 # U+0x0051
        'R' => '610',                            # C+0x52 # U+0x0052
        'S' => '511',                            # C+0x53 # U+0x0053
        'T' => '611',                            # C+0x54 # U+0x0054
        'U' => '677',                            # C+0x55 # U+0x0055
        'V' => '621',                            # C+0x56 # U+0x0056
        'W' => '883',                            # C+0x57 # U+0x0057
        'X' => '600',                            # C+0x58 # U+0x0058
        'Y' => '613',                            # C+0x59 # U+0x0059
        'Z' => '560',                            # C+0x5A # U+0x005A
        'bracketleft' => '401',                  # C+0x5B # U+0x005B
        'backslash' => '355',                    # C+0x5C # U+0x005C
        'bracketright' => '401',                 # C+0x5D # U+0x005D
        'asciicircum' => '585',                  # C+0x5E # U+0x005E
        'underscore' => '585',                   # C+0x5F # U+0x005F
        'grave' => '585',                        # C+0x60 # U+0x0060
        'a' => '532',                            # C+0x61 # U+0x0061
        'b' => '581',                            # C+0x62 # U+0x0062
        'c' => '511',                            # C+0x63 # U+0x0063
        'd' => '580',                            # C+0x64 # U+0x0064
        'e' => '574',                            # C+0x65 # U+0x0065
        'f' => '369',                            # C+0x66 # U+0x0066
        'g' => '501',                            # C+0x67 # U+0x0067
        'h' => '592',                            # C+0x68 # U+0x0068
        'i' => '298',                            # C+0x69 # U+0x0069
        'j' => '366',                            # C+0x6A # U+0x006A
        'k' => '547',                            # C+0x6B # U+0x006B
        'l' => '294',                            # C+0x6C # U+0x006C
        'm' => '859',                            # C+0x6D # U+0x006D
        'n' => '590',                            # C+0x6E # U+0x006E
        'o' => '565',                            # C+0x6F # U+0x006F
        'p' => '582',                            # C+0x70 # U+0x0070
        'q' => '583',                            # C+0x71 # U+0x0071
        'r' => '427',                            # C+0x72 # U+0x0072
        's' => '430',                            # C+0x73 # U+0x0073
        't' => '396',                            # C+0x74 # U+0x0074
        'u' => '590',                            # C+0x75 # U+0x0075
        'v' => '527',                            # C+0x76 # U+0x0076
        'w' => '783',                            # C+0x77 # U+0x0077
        'x' => '552',                            # C+0x78 # U+0x0078
        'y' => '533',                            # C+0x79 # U+0x0079
        'z' => '528',                            # C+0x7A # U+0x007A
        'braceleft' => '433',                    # C+0x7B # U+0x007B
        'bar' => '585',                          # C+0x7C # U+0x007C
        'braceright' => '433',                   # C+0x7D # U+0x007D
        'asciitilde' => '585',                   # C+0x7E # U+0x007E
        'bullet' => '524',                       # C+0x7F # U+0x2022
        'Euro' => '585',                         # C+0x80 # U+0x20AC
        'quotesinglbase' => '367',               # C+0x82 # U+0x201A
        'florin' => '388',                       # C+0x83 # U+0x0192
        'quotedblbase' => '524',                 # C+0x84 # U+0x201E
        'ellipsis' => '734',                     # C+0x85 # U+0x2026
        'dagger' => '458',                       # C+0x86 # U+0x2020
        'daggerdbl' => '458',                    # C+0x87 # U+0x2021
        'circumflex' => '585',                   # C+0x88 # U+0x02C6
        'perthousand' => '1035',                 # C+0x89 # U+0x2030
        'Scaron' => '511',                       # C+0x8A # U+0x0160
        'guilsinglleft' => '367',                # C+0x8B # U+0x2039
        'OE' => '1003',                          # C+0x8C # U+0x0152
        'Zcaron' => '560',                       # C+0x8E # U+0x017D
        'quoteleft' => '367',                    # C+0x91 # U+0x2018
        'quoteright' => '367',                   # C+0x92 # U+0x2019
        'quotedblleft' => '585',                 # C+0x93 # U+0x201C
        'quotedblright' => '585',                # C+0x94 # U+0x201D
        'endash' => '367',                       # C+0x96 # U+0x2013
        'emdash' => '734',                       # C+0x97 # U+0x2014
        'tilde' => '585',                        # C+0x98 # U+0x02DC
        'trademark' => '644',                    # C+0x99 # U+0x2122
        'scaron' => '430',                       # C+0x9A # U+0x0161
        'guilsinglright' => '367',               # C+0x9B # U+0x203A
        'oe' => '920',                           # C+0x9C # U+0x0153
        'zcaron' => '528',                       # C+0x9E # U+0x017E
        'Ydieresis' => '613',                    # C+0x9F # U+0x0178
        'exclamdown' => '367',                   # C+0xA1 # U+0x00A1
        'cent' => '585',                         # C+0xA2 # U+0x00A2
        'sterling' => '524',                     # C+0xA3 # U+0x00A3
        'currency' => '585',                     # C+0xA4 # U+0x00A4
        'yen' => '570',                          # C+0xA5 # U+0x00A5
        'brokenbar' => '585',                    # C+0xA6 # U+0x00A6
        'section' => '453',                      # C+0xA7 # U+0x00A7
        'dieresis' => '585',                     # C+0xA8 # U+0x00A8
        'copyright' => '712',                    # C+0xA9 # U+0x00A9
        'ordfeminine' => '429',                  # C+0xAA # U+0x00AA
        'guillemotleft' => '585',                # C+0xAB # U+0x00AB
        'logicalnot' => '585',                   # C+0xAC # U+0x00AC
        'registered' => '712',                   # C+0xAE # U+0x00AE
        'macron' => '585',                       # C+0xAF # U+0x00AF
        'degree' => '585',                       # C+0xB0 # U+0x00B0
        'plusminus' => '585',                    # C+0xB1 # U+0x00B1
        'twosuperior' => '451',                  # C+0xB2 # U+0x00B2
        'threesuperior' => '453',                # C+0xB3 # U+0x00B3
        'acute' => '585',                        # C+0xB4 # U+0x00B4
        'mu' => '546',                           # C+0xB5 # U+0x00B5
        'paragraph' => '524',                    # C+0xB6 # U+0x00B6
        'periodcentered' => '367',               # C+0xB7 # U+0x00B7
        'cedilla' => '585',                      # C+0xB8 # U+0x00B8
        'onesuperior' => '451',                  # C+0xB9 # U+0x00B9
        'ordmasculine' => '429',                 # C+0xBA # U+0x00BA
        'guillemotright' => '585',               # C+0xBB # U+0x00BB
        'onequarter' => '814',                   # C+0xBC # U+0x00BC
        'onehalf' => '814',                      # C+0xBD # U+0x00BD
        'threequarters' => '814',                # C+0xBE # U+0x00BE
        'questiondown' => '437',                 # C+0xBF # U+0x00BF
        'Agrave' => '633',                       # C+0xC0 # U+0x00C0
        'Aacute' => '633',                       # C+0xC1 # U+0x00C1
        'Acircumflex' => '633',                  # C+0xC2 # U+0x00C2
        'Atilde' => '633',                       # C+0xC3 # U+0x00C3
        'Adieresis' => '633',                    # C+0xC4 # U+0x00C4
        'Aring' => '633',                        # C+0xC5 # U+0x00C5
        'AE' => '935',                           # C+0xC6 # U+0x00C6
        'Ccedilla' => '611',                     # C+0xC7 # U+0x00C7
        'Egrave' => '568',                       # C+0xC8 # U+0x00C8
        'Eacute' => '568',                       # C+0xC9 # U+0x00C9
        'Ecircumflex' => '568',                  # C+0xCA # U+0x00CA
        'Edieresis' => '568',                    # C+0xCB # U+0x00CB
        'Igrave' => '278',                       # C+0xCC # U+0x00CC
        'Iacute' => '278',                       # C+0xCD # U+0x00CD
        'Icircumflex' => '278',                  # C+0xCE # U+0x00CE
        'Idieresis' => '278',                    # C+0xCF # U+0x00CF
        'Eth' => '642',                          # C+0xD0 # U+0x00D0
        'Ntilde' => '667',                       # C+0xD1 # U+0x00D1
        'Ograve' => '703',                       # C+0xD2 # U+0x00D2
        'Oacute' => '703',                       # C+0xD3 # U+0x00D3
        'Ocircumflex' => '703',                  # C+0xD4 # U+0x00D4
        'Otilde' => '703',                       # C+0xD5 # U+0x00D5
        'Odieresis' => '703',                    # C+0xD6 # U+0x00D6
        'multiply' => '585',                     # C+0xD7 # U+0x00D7
        'Oslash' => '683',                       # C+0xD8 # U+0x00D8
        'Ugrave' => '677',                       # C+0xD9 # U+0x00D9
        'Uacute' => '677',                       # C+0xDA # U+0x00DA
        'Ucircumflex' => '677',                  # C+0xDB # U+0x00DB
        'Udieresis' => '677',                    # C+0xDC # U+0x00DC
        'Yacute' => '613',                       # C+0xDD # U+0x00DD
        'Thorn' => '557',                        # C+0xDE # U+0x00DE
        'germandbls' => '546',                   # C+0xDF # U+0x00DF
        'agrave' => '532',                       # C+0xE0 # U+0x00E0
        'aacute' => '532',                       # C+0xE1 # U+0x00E1
        'acircumflex' => '532',                  # C+0xE2 # U+0x00E2
        'atilde' => '532',                       # C+0xE3 # U+0x00E3
        'adieresis' => '532',                    # C+0xE4 # U+0x00E4
        'aring' => '532',                        # C+0xE5 # U+0x00E5
        'ae' => '862',                           # C+0xE6 # U+0x00E6
        'ccedilla' => '511',                     # C+0xE7 # U+0x00E7
        'egrave' => '574',                       # C+0xE8 # U+0x00E8
        'eacute' => '574',                       # C+0xE9 # U+0x00E9
        'ecircumflex' => '574',                  # C+0xEA # U+0x00EA
        'edieresis' => '574',                    # C+0xEB # U+0x00EB
        'igrave' => '298',                       # C+0xEC # U+0x00EC
        'iacute' => '298',                       # C+0xED # U+0x00ED
        'icircumflex' => '298',                  # C+0xEE # U+0x00EE
        'idieresis' => '298',                    # C+0xEF # U+0x00EF
        'eth' => '565',                          # C+0xF0 # U+0x00F0
        'ntilde' => '590',                       # C+0xF1 # U+0x00F1
        'ograve' => '565',                       # C+0xF2 # U+0x00F2
        'oacute' => '565',                       # C+0xF3 # U+0x00F3
        'ocircumflex' => '565',                  # C+0xF4 # U+0x00F4
        'otilde' => '565',                       # C+0xF5 # U+0x00F5
        'odieresis' => '565',                    # C+0xF6 # U+0x00F6
        'divide' => '585',                       # C+0xF7 # U+0x00F7
        'oslash' => '565',                       # C+0xF8 # U+0x00F8
        'ugrave' => '590',                       # C+0xF9 # U+0x00F9
        'uacute' => '590',                       # C+0xFA # U+0x00FA
        'ucircumflex' => '590',                  # C+0xFB # U+0x00FB
        'udieresis' => '590',                    # C+0xFC # U+0x00FC
        'yacute' => '533',                       # C+0xFD # U+0x00FD
        'thorn' => '582',                        # C+0xFE # U+0x00FE
        'ydieresis' => '533',                    # C+0xFF # U+0x00FF
        'middot' => '367',                       # U+0x00B7
        'Abreve' => '633',                       # U+0x0102
        'abreve' => '532',                       # U+0x0103
        'Aogonek' => '633',                      # U+0x0104
        'aogonek' => '532',                      # U+0x0105
        'Cacute' => '611',                       # U+0x0106
        'cacute' => '511',                       # U+0x0107
        'Ccaron' => '611',                       # U+0x010C
        'ccaron' => '511',                       # U+0x010D
        'Dcaron' => '642',                       # U+0x010E
        'dcaron' => '733',                       # U+0x010F
        'Eogonek' => '568',                      # U+0x0118
        'eogonek' => '574',                      # U+0x0119
        'Ecaron' => '568',                       # U+0x011A
        'ecaron' => '574',                       # U+0x011B
        'Gbreve' => '671',                       # U+0x011E
        'gbreve' => '501',                       # U+0x011F
        'dotlessi' => '298',                     # U+0x0131
        'Lacute' => '552',                       # U+0x0139
        'lacute' => '294',                       # U+0x013A
        'Lcaron' => '552',                       # U+0x013D
        'lcaron' => '377',                       # U+0x013E
        'Ldot' => '552',                         # U+0x013F
        'ldot' => '436',                         # U+0x0140
        'Lslash' => '552',                       # U+0x0141
        'lslash' => '294',                       # U+0x0142
        'Nacute' => '667',                       # U+0x0143
        'nacute' => '590',                       # U+0x0144
        'Ncaron' => '667',                       # U+0x0147
        'ncaron' => '590',                       # U+0x0148
        'Racute' => '610',                       # U+0x0154
        'racute' => '427',                       # U+0x0155
        'Rcaron' => '610',                       # U+0x0158
        'rcaron' => '427',                       # U+0x0159
        'Sacute' => '511',                       # U+0x015A
        'sacute' => '430',                       # U+0x015B
        'Scedilla' => '511',                     # U+0x015E
        'scedilla' => '430',                     # U+0x015F
        'Tcaron' => '611',                       # U+0x0164
        'tcaron' => '545',                       # U+0x0165
        'Uring' => '677',                        # U+0x016E
        'uring' => '590',                        # U+0x016F
        'Zacute' => '560',                       # U+0x0179
        'zacute' => '528',                       # U+0x017A
        'Zdot' => '560',                         # U+0x017B
        'zdot' => '528',                         # U+0x017C
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
        'franc' => '583',                        # U+0x20A3
        'partialdiff' => '585',                  # U+0x2202
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
        'dotlessj' => '366',                     # U+0xF6BE
        'fi' => '622',                           # U+0xFB01
        'fl' => '636',                           # U+0xFB02
    }, # HORIZ. WIDTH TABLE
} };

1;
