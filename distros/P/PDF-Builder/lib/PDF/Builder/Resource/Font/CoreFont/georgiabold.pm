package PDF::Builder::Resource::Font::CoreFont::georgiabold;

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::Font::CoreFont::georgiabold - Font-specific information for bold weight Georgia font

I<Not> a standard PDF core font

=cut

sub data { return {
    'fontname' => 'Georgia,Bold',
    'type' => 'TrueType',
    'apiname' => 'GeBo',
    'ascender' => '916',
    'capheight' => '692',
    'descender' => '-219',
    'isfixedpitch' => '0',
    'issymbol' => '0',
    'italicangle' => '0',
    'underlineposition' => '-180',
    'underlinethickness' => '122',
    'xheight' => '484',
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
    'fontbbox' => [ -190, -216, 1295, 912 ],
# source: \Windows\Fonts\georgiab.ttf
# font underline position = -180
# CIDs 0 .. 863 to be output
# fontbbox = (-190 -303 1295 988)
    'wx' => { # HORIZ. WIDTH TABLE
        'A'       => 758,
        'AE'       => 1069,
        'AEacute'       => 1069,
        'Aacute'       => 758,
        'Abreve'       => 758,
        'Acircumflex'       => 758,
        'Adieresis'       => 758,
        'Agrave'       => 758,
        'Alpha'       => 758,
        'Alphatonos'       => 758,
        'Amacron'       => 758,
        'Aogonek'       => 758,
        'Aring'       => 758,
        'Aringacute'       => 758,
        'Atilde'       => 758,
        'B'       => 757,
        'Beta'       => 757,
        'C'       => 715,
        'Cacute'       => 715,
        'Ccaron'       => 715,
        'Ccedilla'       => 715,
        'Ccircumflex'       => 715,
        'Cdotaccent'       => 715,
        'Chi'       => 808,
        'D'       => 833,
        'Dcaron'       => 833,
        'Dcroat'       => 833,
        'Delta'       => 739,
        'E'       => 721,
        'Eacute'       => 721,
        'Ebreve'       => 721,
        'Ecaron'       => 721,
        'Ecircumflex'       => 721,
        'Edieresis'       => 721,
        'Edotaccent'       => 721,
        'Egrave'       => 721,
        'Emacron'       => 721,
        'Eng'       => 839,
        'Eogonek'       => 721,
        'Epsilon'       => 721,
        'Epsilontonos'       => 880,
        'Eta'       => 913,
        'Etatonos'       => 1072,
        'Eth'       => 833,
        'Euro'       => 715,
        'F'       => 671,
        'G'       => 807,
        'Gamma'       => 657,
        'Gbreve'       => 807,
        'Gcircumflex'       => 807,
        'Gcommaaccent'       => 807,
        'Gdotaccent'       => 807,
        'H'       => 913,
        'H18533'       => 604,
        'H18543'       => 354,
        'H18551'       => 354,
        'H22073'       => 604,
        'Hbar'       => 913,
        'Hcircumflex'       => 913,
        'I'       => 445,
        'IJ'       => 996,
        'Iacute'       => 445,
        'Ibreve'       => 445,
        'Icircumflex'       => 445,
        'Idieresis'       => 445,
        'Idotaccent'       => 445,
        'Igrave'       => 445,
        'Imacron'       => 445,
        'Iogonek'       => 445,
        'Iota'       => 445,
        'Iotadieresis'       => 445,
        'Iotatonos'       => 604,
        'Itilde'       => 445,
        'J'       => 595,
        'Jcircumflex'       => 595,
        'K'       => 816,
        'Kappa'       => 816,
        'Kcommaaccent'       => 816,
        'L'       => 685,
        'Lacute'       => 685,
        'Lambda'       => 752,
        'Lcaron'       => 685,
        'Lcommaaccent'       => 685,
        'Ldot'       => 685,
        'Lslash'       => 685,
        'M'       => 1023,
        'Mu'       => 1023,
        'N'       => 839,
        'Nacute'       => 839,
        'Ncaron'       => 839,
        'Ncommaaccent'       => 839,
        'Ntilde'       => 839,
        'Nu'       => 839,
        'O'       => 819,
        'OE'       => 1100,
        'Oacute'       => 819,
        'Obreve'       => 819,
        'Ocircumflex'       => 819,
        'Odieresis'       => 819,
        'Ograve'       => 819,
        'Ohungarumlaut'       => 819,
        'Omacron'       => 819,
        'Omega'       => 874,
        'Omegatonos'       => 960,
        'Omicron'       => 819,
        'Omicrontonos'       => 922,
        'Oslash'       => 819,
        'Oslashacute'       => 819,
        'Otilde'       => 819,
        'P'       => 701,
        'Phi'       => 911,
        'Pi'       => 900,
        'Psi'       => 1011,
        'Q'       => 819,
        'R'       => 797,
        'Racute'       => 797,
        'Rcaron'       => 797,
        'Rcommaaccent'       => 797,
        'Rho'       => 701,
        'S'       => 648,
        'SF010000'       => 708,
        'SF020000'       => 708,
        'SF030000'       => 708,
        'SF040000'       => 708,
        'SF100000'       => 708,
        'SF110000'       => 708,
        'Sacute'       => 648,
        'Scaron'       => 648,
        'Scedilla'       => 648,
        'Scircumflex'       => 648,
        'Scommaaccent'       => 648,
        'Sigma'       => 679,
        'T'       => 684,
        'Tau'       => 684,
        'Tbar'       => 684,
        'Tcaron'       => 684,
        'Tcedilla'       => 684,
        'Tcommaaccent'       => 684,
        'Theta'       => 822,
        'Thorn'       => 708,
        'U'       => 833,
        'Uacute'       => 833,
        'Ubreve'       => 833,
        'Ucircumflex'       => 833,
        'Udieresis'       => 833,
        'Ugrave'       => 833,
        'Uhungarumlaut'       => 833,
        'Umacron'       => 833,
        'Uogonek'       => 833,
        'Upsilon'       => 731,
        'Upsilondieresis'       => 731,
        'Upsilontonos'       => 935,
        'Uring'       => 833,
        'Utilde'       => 833,
        'V'       => 762,
        'W'       => 1126,
        'Wacute'       => 1126,
        'Wcircumflex'       => 1126,
        'Wdieresis'       => 1126,
        'Wgrave'       => 1126,
        'X'       => 808,
        'Xi'       => 766,
        'Y'       => 731,
        'Yacute'       => 731,
        'Ycircumflex'       => 731,
        'Ydieresis'       => 731,
        'Ygrave'       => 731,
        'Z'       => 689,
        'Zacute'       => 689,
        'Zcaron'       => 689,
        'Zdotaccent'       => 689,
        'Zeta'       => 689,
        'a'       => 595,
        'aacute'       => 595,
        'abreve'       => 595,
        'acircumflex'       => 595,
        'acute'       => 500,
        'acutecomb'       => 500,
        'adieresis'       => 595,
        'ae'       => 857,
        'aeacute'       => 857,
        'afii00208'       => 927,
        'afii10017'       => 758,
        'afii10018'       => 747,
        'afii10019'       => 757,
        'afii10020'       => 657,
        'afii10021'       => 800,
        'afii10022'       => 721,
        'afii10023'       => 721,
        'afii10024'       => 1129,
        'afii10025'       => 676,
        'afii10026'       => 921,
        'afii10027'       => 921,
        'afii10028'       => 799,
        'afii10029'       => 834,
        'afii10030'       => 1023,
        'afii10031'       => 913,
        'afii10032'       => 819,
        'afii10033'       => 900,
        'afii10034'       => 701,
        'afii10035'       => 715,
        'afii10036'       => 684,
        'afii10037'       => 727,
        'afii10038'       => 911,
        'afii10039'       => 808,
        'afii10040'       => 901,
        'afii10041'       => 832,
        'afii10042'       => 1288,
        'afii10043'       => 1288,
        'afii10044'       => 863,
        'afii10045'       => 1103,
        'afii10046'       => 733,
        'afii10047'       => 729,
        'afii10048'       => 1181,
        'afii10049'       => 792,
        'afii10050'       => 649,
        'afii10051'       => 883,
        'afii10052'       => 657,
        'afii10053'       => 733,
        'afii10054'       => 648,
        'afii10055'       => 445,
        'afii10056'       => 445,
        'afii10057'       => 595,
        'afii10058'       => 1124,
        'afii10059'       => 1197,
        'afii10060'       => 935,
        'afii10061'       => 799,
        'afii10062'       => 727,
        'afii10065'       => 595,
        'afii10066'       => 625,
        'afii10067'       => 619,
        'afii10068'       => 497,
        'afii10069'       => 615,
        'afii10070'       => 571,
        'afii10071'       => 571,
        'afii10072'       => 891,
        'afii10073'       => 539,
        'afii10074'       => 717,
        'afii10075'       => 717,
        'afii10076'       => 640,
        'afii10077'       => 656,
        'afii10078'       => 802,
        'afii10079'       => 709,
        'afii10080'       => 635,
        'afii10081'       => 699,
        'afii10082'       => 657,
        'afii10083'       => 531,
        'afii10084'       => 545,
        'afii10085'       => 562,
        'afii10086'       => 875,
        'afii10087'       => 587,
        'afii10088'       => 702,
        'afii10089'       => 666,
        'afii10090'       => 989,
        'afii10091'       => 992,
        'afii10092'       => 680,
        'afii10093'       => 915,
        'afii10094'       => 592,
        'afii10095'       => 546,
        'afii10096'       => 937,
        'afii10097'       => 639,
        'afii10098'       => 495,
        'afii10099'       => 670,
        'afii10100'       => 497,
        'afii10101'       => 558,
        'afii10102'       => 512,
        'afii10103'       => 353,
        'afii10104'       => 353,
        'afii10105'       => 346,
        'afii10106'       => 882,
        'afii10107'       => 932,
        'afii10108'       => 679,
        'afii10109'       => 640,
        'afii10110'       => 562,
        'afii10145'       => 901,
        'afii10193'       => 699,
        'afii61248'       => 879,
        'afii61289'       => 323,
        'afii61352'       => 1279,
        'agrave'       => 595,
        'alpha'       => 679,
        'alphatonos'       => 679,
        'amacron'       => 595,
        'ampersand'       => 799,
        'anoteleia'       => 367,
        'aogonek'       => 595,
        'approxequal'       => 703,
        'aring'       => 595,
        'aringacute'       => 595,
        'asciicircum'       => 703,
        'asciitilde'       => 703,
        'asterisk'       => 481,
        'at'       => 966,
        'atilde'       => 595,
        'b'       => 645,
        'backslash'       => 471,
        'bar'       => 387,
        'beta'       => 656,
        'braceleft'       => 500,
        'braceright'       => 500,
        'bracketleft'       => 446,
        'bracketright'       => 446,
        'breve'       => 500,
        'brevecmb'       => 500,
        'brokenbar'       => 387,
        'bullet'       => 437,
        'c'       => 531,
        'cacute'       => 531,
        'caron'       => 500,
        'caroncmb'       => 500,
        'ccaron'       => 531,
        'ccedilla'       => 531,
        'ccircumflex'       => 531,
        'cdotaccent'       => 531,
        'cedilla'       => 500,
        'cent'       => 605,
        'chi'       => 566,
        'circumflex'       => 500,
        'circumflexcmb'       => 500,
        'colon'       => 367,
        'colontriangularhalfmod'       => 500,
        'comma'       => 328,
        'copyright'       => 941,
        'currency'       => 703,
        'd'       => 663,
        'dagger'       => 481,
        'daggerdbl'       => 481,
        'dcaron'       => 825,
        'dcroat'       => 663,
        'degree'       => 419,
        'delta'       => 635,
        'dieresis'       => 500,
        'dieresiscmb'       => 500,
        'dieresistonos'       => 500,
        'divide'       => 703,
        'dollar'       => 640,
        'dotaccent'       => 500,
        'dotlessi'       => 353,
        'dotlessj'       => 346,
        'e'       => 571,
        'eacute'       => 571,
        'ebreve'       => 571,
        'ecaron'       => 571,
        'ecircumflex'       => 571,
        'edieresis'       => 571,
        'edotaccent'       => 571,
        'egrave'       => 571,
        'eight'       => 676,
        'eightinferior'       => 551,
        'eightsuperior'       => 551,
        'ellipsis'       => 941,
        'emacron'       => 571,
        'emdash'       => 927,
        'endash'       => 703,
        'eng'       => 680,
        'eogonek'       => 571,
        'epsilon'       => 535,
        'epsilontonos'       => 535,
        'equal'       => 703,
        'estimated'       => 649,
        'eta'       => 660,
        'etatonos'       => 660,
        'eth'       => 637,
        'exclam'       => 376,
        'exclamdbl'       => 664,
        'exclamdown'       => 376,
        'f'       => 393,
        'ff'       => 734,
        'ffi'       => 1037,
        'ffl'       => 1037,
        'fi'       => 694,
        'five'       => 599,
        'fiveeighths'       => 1071,
        'fiveinferior'       => 551,
        'fivesuperior'       => 551,
        'fl'       => 705,
        'florin'       => 579,
        'four'       => 649,
        'fourinferior'       => 551,
        'foursuperior'       => 551,
        'fraction'       => 94,
        'franc'       => 689,
        'g'       => 576,
        'gamma'       => 570,
        'gbreve'       => 576,
        'gcircumflex'       => 576,
        'gcommaaccent'       => 576,
        'gdotaccent'       => 576,
        'germandbls'       => 657,
        'grave'       => 500,
        'gravecomb'       => 500,
        'greater'       => 703,
        'greaterequal'       => 703,
        'guillemotleft'       => 610,
        'guillemotright'       => 610,
        'guilsinglleft'       => 395,
        'guilsinglright'       => 395,
        'h'       => 679,
        'hbar'       => 679,
        'hcircumflex'       => 679,
        'hungarumlaut'       => 500,
        'hungarumlautcmb'       => 500,
        'hyphen'       => 378,
        'i'       => 353,
        'iacute'       => 353,
        'ibreve'       => 353,
        'icircumflex'       => 353,
        'idieresis'       => 353,
        'igrave'       => 353,
        'ij'       => 676,
        'imacron'       => 353,
        'infinity'       => 798,
        'integral'       => 627,
        'iogonek'       => 353,
        'iota'       => 342,
        'iotadieresis'       => 342,
        'iotadieresistonos'       => 342,
        'iotatonos'       => 342,
        'itilde'       => 353,
        'j'       => 346,
        'jcircumflex'       => 346,
        'k'       => 631,
        'kappa'       => 630,
        'kcommaaccent'       => 631,
        'kgreenlandic'       => 642,
        'l'       => 344,
        'lacute'       => 344,
        'lambda'       => 527,
        'lcaron'       => 507,
        'lcommaaccent'       => 344,
        'ldot'       => 536,
        'less'       => 703,
        'lessequal'       => 703,
        'lira'       => 689,
        'logicalnot'       => 703,
        'longs'       => 353,
        'lozenge'       => 717,
        'lslash'       => 344,
        'm'       => 1015,
        'macron'       => 703,
        'minus'       => 703,
        'minute'       => 321,
        'mu'       => 669,
        'multiply'       => 703,
        'musicalnote'       => 500,
        'n'       => 689,
        'nacute'       => 689,
        'napostrophe'       => 827,
        'ncaron'       => 689,
        'ncommaaccent'       => 689,
        'nine'       => 647,
        'nineinferior'       => 551,
        'ninesuperior'       => 551,
        'notequal'       => 703,
        'nsuperior'       => 588,
        'ntilde'       => 689,
        'nu'       => 561,
        'numbersign'       => 703,
        'o'       => 635,
        'oacute'       => 635,
        'obreve'       => 635,
        'ocircumflex'       => 635,
        'odieresis'       => 635,
        'oe'       => 937,
        'ogonek'       => 500,
        'ograve'       => 635,
        'ohungarumlaut'       => 635,
        'omacron'       => 635,
        'omega'       => 812,
        'omegatonos'       => 812,
        'omicron'       => 635,
        'omicrontonos'       => 635,
        'one'       => 489,
        'oneeighth'       => 1071,
        'onehalf'       => 1071,
        'oneinferior'       => 551,
        'onequarter'       => 1071,
        'onesuperior'       => 551,
        'openbullet'       => 354,
        'ordfeminine'       => 551,
        'ordmasculine'       => 551,
        'oslash'       => 635,
        'oslashacute'       => 635,
        'otilde'       => 635,
        'overline'       => 703,
        'p'       => 657,
        'paragraph'       => 548,
        'parenleft'       => 446,
        'parenright'       => 446,
        'partialdiff'       => 646,
        'percent'       => 879,
        'period'       => 328,
        'periodcentered'       => 337,
        'perthousand'       => 1308,
        'peseta'       => 1355,
        'phi'       => 823,
        'pi'       => 659,
        'plus'       => 703,
        'plusminus'       => 703,
        'product'       => 932,
        'psi'       => 840,
        'q'       => 648,
        'question'       => 548,
        'questiondown'       => 548,
        'questiongreek'       => 367,
        'quotedbl'       => 509,
        'quotedblbase'       => 519,
        'quotedblleft'       => 519,
        'quotedblright'       => 519,
        'quoteleft'       => 268,
        'quotereversed'       => 268,
        'quoteright'       => 268,
        'quotesinglbase'       => 268,
        'quotesingle'       => 269,
        'r'       => 520,
        'racute'       => 520,
        'radical'       => 716,
        'rcaron'       => 520,
        'rcommaaccent'       => 520,
        'registered'       => 941,
        'rho'       => 646,
        'ring'       => 500,
        's'       => 512,
        'sacute'       => 512,
        'scaron'       => 512,
        'scedilla'       => 512,
        'scircumflex'       => 512,
        'scommaaccent'       => 512,
        'second'       => 532,
        'section'       => 563,
        'seven'       => 554,
        'seveneighths'       => 1071,
        'seveninferior'       => 551,
        'sevensuperior'       => 551,
        'sigma'       => 669,
        'sigma1'       => 513,
        'six'       => 647,
        'sixinferior'       => 551,
        'sixsuperior'       => 551,
        'slash'       => 471,
        'space'       => 253,
        'sterling'       => 689,
        'summation'       => 729,
        't'       => 397,
        'tau'       => 485,
        'tbar'       => 397,
        'tcaron'       => 397,
        'tcedilla'       => 397,
        'tcommaaccent'       => 397,
        'theta'       => 640,
        'thorn'       => 645,
        'three'       => 624,
        'threeeighths'       => 1071,
        'threeinferior'       => 551,
        'threequarters'       => 1071,
        'threesuperior'       => 551,
        'tilde'       => 500,
        'tonos'       => 500,
        'trademark'       => 947,
        'two'       => 626,
        'twoinferior'       => 551,
        'twosuperior'       => 551,
        'u'       => 676,
        'uacute'       => 676,
        'ubreve'       => 676,
        'ucircumflex'       => 676,
        'udieresis'       => 676,
        'ugrave'       => 676,
        'uhungarumlaut'       => 676,
        'umacron'       => 676,
        'underscore'       => 703,
        'underscoredbl'       => 703,
        'uni0326'       => 500,
        'uni1E9E'       => 820,
        'uni20B8'       => 634,
        'uni20B9'       => 634,
        'uni20BA'       => 634,
        'uni20BB'       => 743,
        'uni20BC'       => 988,
        'uni20BD'       => 650,
        'uni20BE'       => 786,
        'uni2120'       => 1250,
        'uogonek'       => 676,
        'upsilon'       => 592,
        'upsilondieresis'       => 592,
        'upsilondieresistonos'       => 592,
        'upsilontonos'       => 592,
        'uring'       => 676,
        'utilde'       => 676,
        'v'       => 566,
        'w'       => 863,
        'wacute'       => 863,
        'wcircumflex'       => 863,
        'wdieresis'       => 863,
        'wgrave'       => 863,
        'x'       => 587,
        'xi'       => 498,
        'y'       => 562,
        'yacute'       => 562,
        'ycircumflex'       => 562,
        'ydieresis'       => 562,
        'yen'       => 732,
        'ygrave'       => 562,
        'z'       => 525,
        'zacute'       => 525,
        'zcaron'       => 525,
        'zdotaccent'       => 525,
        'zero'       => 701,
        'zeroinferior'       => 551,
        'zerosuperior'       => 551,
        'zeta'       => 462,
    },
    'wxold' => { # HORIZ. WIDTH TABLE
        'space' => '253',                        # C+0x20 # U+0x0020
        'exclam' => '376',                       # C+0x21 # U+0x0021
        'quotedbl' => '509',                     # C+0x22 # U+0x0022
        'numbersign' => '703',                   # C+0x23 # U+0x0023
        'dollar' => '640',                       # C+0x24 # U+0x0024
        'percent' => '879',                      # C+0x25 # U+0x0025
        'ampersand' => '799',                    # C+0x26 # U+0x0026
        'quotesingle' => '269',                  # C+0x27 # U+0x0027
        'parenleft' => '446',                    # C+0x28 # U+0x0028
        'parenright' => '446',                   # C+0x29 # U+0x0029
        'asterisk' => '481',                     # C+0x2A # U+0x002A
        'plus' => '703',                         # C+0x2B # U+0x002B
        'comma' => '328',                        # C+0x2C # U+0x002C
        'hyphen' => '378',                       # C+0x2D # U+0x002D
        'period' => '328',                       # C+0x2E # U+0x002E
        'slash' => '471',                        # C+0x2F # U+0x002F
        'zero' => '701',                         # C+0x30 # U+0x0030
        'one' => '489',                          # C+0x31 # U+0x0031
        'two' => '626',                          # C+0x32 # U+0x0032
        'three' => '624',                        # C+0x33 # U+0x0033
        'four' => '649',                         # C+0x34 # U+0x0034
        'five' => '599',                         # C+0x35 # U+0x0035
        'six' => '647',                          # C+0x36 # U+0x0036
        'seven' => '554',                        # C+0x37 # U+0x0037
        'eight' => '676',                        # C+0x38 # U+0x0038
        'nine' => '647',                         # C+0x39 # U+0x0039
        'colon' => '367',                        # C+0x3A # U+0x003A
        'semicolon' => '367',                    # C+0x3B # U+0x003B
        'less' => '703',                         # C+0x3C # U+0x003C
        'equal' => '703',                        # C+0x3D # U+0x003D
        'greater' => '703',                      # C+0x3E # U+0x003E
        'question' => '548',                     # C+0x3F # U+0x003F
        'at' => '966',                           # C+0x40 # U+0x0040
        'A' => '758',                            # C+0x41 # U+0x0041
        'B' => '757',                            # C+0x42 # U+0x0042
        'C' => '715',                            # C+0x43 # U+0x0043
        'D' => '833',                            # C+0x44 # U+0x0044
        'E' => '721',                            # C+0x45 # U+0x0045
        'F' => '671',                            # C+0x46 # U+0x0046
        'G' => '807',                            # C+0x47 # U+0x0047
        'H' => '913',                            # C+0x48 # U+0x0048
        'I' => '445',                            # C+0x49 # U+0x0049
        'J' => '595',                            # C+0x4A # U+0x004A
        'K' => '816',                            # C+0x4B # U+0x004B
        'L' => '685',                            # C+0x4C # U+0x004C
        'M' => '1023',                           # C+0x4D # U+0x004D
        'N' => '839',                            # C+0x4E # U+0x004E
        'O' => '819',                            # C+0x4F # U+0x004F
        'P' => '701',                            # C+0x50 # U+0x0050
        'Q' => '819',                            # C+0x51 # U+0x0051
        'R' => '797',                            # C+0x52 # U+0x0052
        'S' => '648',                            # C+0x53 # U+0x0053
        'T' => '684',                            # C+0x54 # U+0x0054
        'U' => '833',                            # C+0x55 # U+0x0055
        'V' => '762',                            # C+0x56 # U+0x0056
        'W' => '1126',                           # C+0x57 # U+0x0057
        'X' => '808',                            # C+0x58 # U+0x0058
        'Y' => '731',                            # C+0x59 # U+0x0059
        'Z' => '689',                            # C+0x5A # U+0x005A
        'bracketleft' => '446',                  # C+0x5B # U+0x005B
        'backslash' => '471',                    # C+0x5C # U+0x005C
        'bracketright' => '446',                 # C+0x5D # U+0x005D
        'asciicircum' => '703',                  # C+0x5E # U+0x005E
        'underscore' => '703',                   # C+0x5F # U+0x005F
        'grave' => '500',                        # C+0x60 # U+0x0060
        'a' => '595',                            # C+0x61 # U+0x0061
        'b' => '645',                            # C+0x62 # U+0x0062
        'c' => '531',                            # C+0x63 # U+0x0063
        'd' => '663',                            # C+0x64 # U+0x0064
        'e' => '571',                            # C+0x65 # U+0x0065
        'f' => '393',                            # C+0x66 # U+0x0066
        'g' => '576',                            # C+0x67 # U+0x0067
        'h' => '679',                            # C+0x68 # U+0x0068
        'i' => '353',                            # C+0x69 # U+0x0069
        'j' => '346',                            # C+0x6A # U+0x006A
        'k' => '631',                            # C+0x6B # U+0x006B
        'l' => '344',                            # C+0x6C # U+0x006C
        'm' => '1015',                           # C+0x6D # U+0x006D
        'n' => '689',                            # C+0x6E # U+0x006E
        'o' => '635',                            # C+0x6F # U+0x006F
        'p' => '657',                            # C+0x70 # U+0x0070
        'q' => '648',                            # C+0x71 # U+0x0071
        'r' => '520',                            # C+0x72 # U+0x0072
        's' => '512',                            # C+0x73 # U+0x0073
        't' => '397',                            # C+0x74 # U+0x0074
        'u' => '676',                            # C+0x75 # U+0x0075
        'v' => '566',                            # C+0x76 # U+0x0076
        'w' => '863',                            # C+0x77 # U+0x0077
        'x' => '587',                            # C+0x78 # U+0x0078
        'y' => '562',                            # C+0x79 # U+0x0079
        'z' => '525',                            # C+0x7A # U+0x007A
        'braceleft' => '500',                    # C+0x7B # U+0x007B
        'bar' => '387',                          # C+0x7C # U+0x007C
        'braceright' => '500',                   # C+0x7D # U+0x007D
        'asciitilde' => '703',                   # C+0x7E # U+0x007E
        'bullet' => '437',                       # C+0x7F # U+0x2022
        'Euro' => '715',                         # C+0x80 # U+0x20AC
        'quotesinglbase' => '268',               # C+0x82 # U+0x201A
        'florin' => '579',                       # C+0x83 # U+0x0192
        'quotedblbase' => '519',                 # C+0x84 # U+0x201E
        'ellipsis' => '941',                     # C+0x85 # U+0x2026
        'dagger' => '481',                       # C+0x86 # U+0x2020
        'daggerdbl' => '481',                    # C+0x87 # U+0x2021
        'circumflex' => '500',                   # C+0x88 # U+0x02C6
        'perthousand' => '1308',                 # C+0x89 # U+0x2030
        'Scaron' => '648',                       # C+0x8A # U+0x0160
        'guilsinglleft' => '395',                # C+0x8B # U+0x2039
        'OE' => '1100',                          # C+0x8C # U+0x0152
        'Zcaron' => '689',                       # C+0x8E # U+0x017D
        'quoteleft' => '268',                    # C+0x91 # U+0x2018
        'quoteright' => '268',                   # C+0x92 # U+0x2019
        'quotedblleft' => '519',                 # C+0x93 # U+0x201C
        'quotedblright' => '519',                # C+0x94 # U+0x201D
        'endash' => '703',                       # C+0x96 # U+0x2013
        'emdash' => '927',                       # C+0x97 # U+0x2014
        'tilde' => '500',                        # C+0x98 # U+0x02DC
        'trademark' => '947',                    # C+0x99 # U+0x2122
        'scaron' => '512',                       # C+0x9A # U+0x0161
        'guilsinglright' => '395',               # C+0x9B # U+0x203A
        'oe' => '937',                           # C+0x9C # U+0x0153
        'zcaron' => '525',                       # C+0x9E # U+0x017E
        'Ydieresis' => '731',                    # C+0x9F # U+0x0178
        'exclamdown' => '376',                   # C+0xA1 # U+0x00A1
        'cent' => '605',                         # C+0xA2 # U+0x00A2
        'sterling' => '689',                     # C+0xA3 # U+0x00A3
        'currency' => '703',                     # C+0xA4 # U+0x00A4
        'yen' => '732',                          # C+0xA5 # U+0x00A5
        'brokenbar' => '387',                    # C+0xA6 # U+0x00A6
        'section' => '563',                      # C+0xA7 # U+0x00A7
        'dieresis' => '500',                     # C+0xA8 # U+0x00A8
        'copyright' => '941',                    # C+0xA9 # U+0x00A9
        'ordfeminine' => '551',                  # C+0xAA # U+0x00AA
        'guillemotleft' => '610',                # C+0xAB # U+0x00AB
        'logicalnot' => '703',                   # C+0xAC # U+0x00AC
        'registered' => '941',                   # C+0xAE # U+0x00AE
        'macron' => '500',                       # C+0xAF # U+0x00AF
        'degree' => '419',                       # C+0xB0 # U+0x00B0
        'plusminus' => '703',                    # C+0xB1 # U+0x00B1
        'twosuperior' => '551',                  # C+0xB2 # U+0x00B2
        'threesuperior' => '551',                # C+0xB3 # U+0x00B3
        'acute' => '500',                        # C+0xB4 # U+0x00B4
        'mu' => '669',                           # C+0xB5 # U+0x00B5
        'paragraph' => '548',                    # C+0xB6 # U+0x00B6
        'periodcentered' => '337',               # C+0xB7 # U+0x00B7
        'cedilla' => '500',                      # C+0xB8 # U+0x00B8
        'onesuperior' => '551',                  # C+0xB9 # U+0x00B9
        'ordmasculine' => '551',                 # C+0xBA # U+0x00BA
        'guillemotright' => '610',               # C+0xBB # U+0x00BB
        'onequarter' => '1071',                  # C+0xBC # U+0x00BC
        'onehalf' => '1071',                     # C+0xBD # U+0x00BD
        'threequarters' => '1071',               # C+0xBE # U+0x00BE
        'questiondown' => '548',                 # C+0xBF # U+0x00BF
        'Agrave' => '758',                       # C+0xC0 # U+0x00C0
        'Aacute' => '758',                       # C+0xC1 # U+0x00C1
        'Acircumflex' => '758',                  # C+0xC2 # U+0x00C2
        'Atilde' => '758',                       # C+0xC3 # U+0x00C3
        'Adieresis' => '758',                    # C+0xC4 # U+0x00C4
        'Aring' => '758',                        # C+0xC5 # U+0x00C5
        'AE' => '1069',                          # C+0xC6 # U+0x00C6
        'Ccedilla' => '715',                     # C+0xC7 # U+0x00C7
        'Egrave' => '721',                       # C+0xC8 # U+0x00C8
        'Eacute' => '721',                       # C+0xC9 # U+0x00C9
        'Ecircumflex' => '721',                  # C+0xCA # U+0x00CA
        'Edieresis' => '721',                    # C+0xCB # U+0x00CB
        'Igrave' => '445',                       # C+0xCC # U+0x00CC
        'Iacute' => '445',                       # C+0xCD # U+0x00CD
        'Icircumflex' => '445',                  # C+0xCE # U+0x00CE
        'Idieresis' => '445',                    # C+0xCF # U+0x00CF
        'Eth' => '833',                          # C+0xD0 # U+0x00D0
        'Ntilde' => '839',                       # C+0xD1 # U+0x00D1
        'Ograve' => '819',                       # C+0xD2 # U+0x00D2
        'Oacute' => '819',                       # C+0xD3 # U+0x00D3
        'Ocircumflex' => '819',                  # C+0xD4 # U+0x00D4
        'Otilde' => '819',                       # C+0xD5 # U+0x00D5
        'Odieresis' => '819',                    # C+0xD6 # U+0x00D6
        'multiply' => '703',                     # C+0xD7 # U+0x00D7
        'Oslash' => '819',                       # C+0xD8 # U+0x00D8
        'Ugrave' => '833',                       # C+0xD9 # U+0x00D9
        'Uacute' => '833',                       # C+0xDA # U+0x00DA
        'Ucircumflex' => '833',                  # C+0xDB # U+0x00DB
        'Udieresis' => '833',                    # C+0xDC # U+0x00DC
        'Yacute' => '731',                       # C+0xDD # U+0x00DD
        'Thorn' => '708',                        # C+0xDE # U+0x00DE
        'germandbls' => '657',                   # C+0xDF # U+0x00DF
        'agrave' => '595',                       # C+0xE0 # U+0x00E0
        'aacute' => '595',                       # C+0xE1 # U+0x00E1
        'acircumflex' => '595',                  # C+0xE2 # U+0x00E2
        'atilde' => '595',                       # C+0xE3 # U+0x00E3
        'adieresis' => '595',                    # C+0xE4 # U+0x00E4
        'aring' => '595',                        # C+0xE5 # U+0x00E5
        'ae' => '857',                           # C+0xE6 # U+0x00E6
        'ccedilla' => '531',                     # C+0xE7 # U+0x00E7
        'egrave' => '571',                       # C+0xE8 # U+0x00E8
        'eacute' => '571',                       # C+0xE9 # U+0x00E9
        'ecircumflex' => '571',                  # C+0xEA # U+0x00EA
        'edieresis' => '571',                    # C+0xEB # U+0x00EB
        'igrave' => '353',                       # C+0xEC # U+0x00EC
        'iacute' => '353',                       # C+0xED # U+0x00ED
        'icircumflex' => '353',                  # C+0xEE # U+0x00EE
        'idieresis' => '353',                    # C+0xEF # U+0x00EF
        'eth' => '637',                          # C+0xF0 # U+0x00F0
        'ntilde' => '689',                       # C+0xF1 # U+0x00F1
        'ograve' => '635',                       # C+0xF2 # U+0x00F2
        'oacute' => '635',                       # C+0xF3 # U+0x00F3
        'ocircumflex' => '635',                  # C+0xF4 # U+0x00F4
        'otilde' => '635',                       # C+0xF5 # U+0x00F5
        'odieresis' => '635',                    # C+0xF6 # U+0x00F6
        'divide' => '703',                       # C+0xF7 # U+0x00F7
        'oslash' => '635',                       # C+0xF8 # U+0x00F8
        'ugrave' => '676',                       # C+0xF9 # U+0x00F9
        'uacute' => '676',                       # C+0xFA # U+0x00FA
        'ucircumflex' => '676',                  # C+0xFB # U+0x00FB
        'udieresis' => '676',                    # C+0xFC # U+0x00FC
        'yacute' => '562',                       # C+0xFD # U+0x00FD
        'thorn' => '645',                        # C+0xFE # U+0x00FE
        'ydieresis' => '562',                    # C+0xFF # U+0x00FF
        'middot' => '337',                       # U+0x00B7
        'Amacron' => '758',                      # U+0x0100
        'amacron' => '595',                      # U+0x0101
        'Abreve' => '758',                       # U+0x0102
        'abreve' => '595',                       # U+0x0103
        'Aogonek' => '758',                      # U+0x0104
        'aogonek' => '595',                      # U+0x0105
        'Cacute' => '715',                       # U+0x0106
        'cacute' => '531',                       # U+0x0107
        'Ccircumflex' => '715',                  # U+0x0108
        'ccircumflex' => '531',                  # U+0x0109
        'Cdotaccent' => '715',                   # U+0x010A
        'cdotaccent' => '531',                   # U+0x010B
        'Ccaron' => '715',                       # U+0x010C
        'ccaron' => '531',                       # U+0x010D
        'Dcaron' => '833',                       # U+0x010E
        'dcaron' => '825',                       # U+0x010F
        'Dcroat' => '833',                       # U+0x0110
        'dcroat' => '663',                       # U+0x0111
        'Emacron' => '721',                      # U+0x0112
        'emacron' => '571',                      # U+0x0113
        'Ebreve' => '721',                       # U+0x0114
        'ebreve' => '571',                       # U+0x0115
        'Edotaccent' => '721',                   # U+0x0116
        'edotaccent' => '571',                   # U+0x0117
        'Eogonek' => '721',                      # U+0x0118
        'eogonek' => '571',                      # U+0x0119
        'Ecaron' => '721',                       # U+0x011A
        'ecaron' => '571',                       # U+0x011B
        'Gcircumflex' => '807',                  # U+0x011C
        'gcircumflex' => '576',                  # U+0x011D
        'Gbreve' => '807',                       # U+0x011E
        'gbreve' => '576',                       # U+0x011F
        'Gdotaccent' => '807',                   # U+0x0120
        'gdotaccent' => '576',                   # U+0x0121
        'Gcommaaccent' => '807',                 # U+0x0122
        'gcommaaccent' => '576',                 # U+0x0123
        'Hcircumflex' => '913',                  # U+0x0124
        'hcircumflex' => '679',                  # U+0x0125
        'Hbar' => '913',                         # U+0x0126
        'hbar' => '679',                         # U+0x0127
        'Itilde' => '445',                       # U+0x0128
        'itilde' => '353',                       # U+0x0129
        'Imacron' => '445',                      # U+0x012A
        'imacron' => '353',                      # U+0x012B
        'Ibreve' => '445',                       # U+0x012C
        'ibreve' => '353',                       # U+0x012D
        'Iogonek' => '445',                      # U+0x012E
        'iogonek' => '353',                      # U+0x012F
        'Idotaccent' => '445',                   # U+0x0130
        'dotlessi' => '353',                     # U+0x0131
        'IJ' => '996',                           # U+0x0132
        'ij' => '676',                           # U+0x0133
        'Jcircumflex' => '595',                  # U+0x0134
        'jcircumflex' => '346',                  # U+0x0135
        'Kcommaaccent' => '816',                 # U+0x0136
        'kcommaaccent' => '631',                 # U+0x0137
        'kgreenlandic' => '642',                 # U+0x0138
        'Lacute' => '685',                       # U+0x0139
        'lacute' => '344',                       # U+0x013A
        'Lcommaaccent' => '685',                 # U+0x013B
        'lcommaaccent' => '344',                 # U+0x013C
        'Lcaron' => '685',                       # U+0x013D
        'lcaron' => '507',                       # U+0x013E
        'Ldot' => '685',                         # U+0x013F
        'ldot' => '536',                         # U+0x0140
        'Lslash' => '685',                       # U+0x0141
        'lslash' => '344',                       # U+0x0142
        'Nacute' => '839',                       # U+0x0143
        'nacute' => '689',                       # U+0x0144
        'Ncommaaccent' => '839',                 # U+0x0145
        'ncommaaccent' => '689',                 # U+0x0146
        'Ncaron' => '839',                       # U+0x0147
        'ncaron' => '689',                       # U+0x0148
        'napostrophe' => '827',                  # U+0x0149
        'Eng' => '839',                          # U+0x014A
        'eng' => '680',                          # U+0x014B
        'Omacron' => '819',                      # U+0x014C
        'omacron' => '635',                      # U+0x014D
        'Obreve' => '819',                       # U+0x014E
        'obreve' => '635',                       # U+0x014F
        'Ohungarumlaut' => '819',                # U+0x0150
        'ohungarumlaut' => '635',                # U+0x0151
        'Racute' => '797',                       # U+0x0154
        'racute' => '520',                       # U+0x0155
        'Rcommaaccent' => '797',                 # U+0x0156
        'rcommaaccent' => '520',                 # U+0x0157
        'Rcaron' => '797',                       # U+0x0158
        'rcaron' => '520',                       # U+0x0159
        'Sacute' => '648',                       # U+0x015A
        'sacute' => '512',                       # U+0x015B
        'Scircumflex' => '648',                  # U+0x015C
        'scircumflex' => '512',                  # U+0x015D
        'Scedilla' => '648',                     # U+0x015E
        'scedilla' => '512',                     # U+0x015F
        'Tcommaaccent' => '684',                 # U+0x0162
        'tcommaaccent' => '397',                 # U+0x0163
        'Tcaron' => '684',                       # U+0x0164
        'tcaron' => '397',                       # U+0x0165
        'Tbar' => '684',                         # U+0x0166
        'tbar' => '397',                         # U+0x0167
        'Utilde' => '833',                       # U+0x0168
        'utilde' => '676',                       # U+0x0169
        'Umacron' => '833',                      # U+0x016A
        'umacron' => '676',                      # U+0x016B
        'Ubreve' => '833',                       # U+0x016C
        'ubreve' => '676',                       # U+0x016D
        'Uring' => '833',                        # U+0x016E
        'uring' => '676',                        # U+0x016F
        'Uhungarumlaut' => '833',                # U+0x0170
        'uhungarumlaut' => '676',                # U+0x0171
        'Uogonek' => '833',                      # U+0x0172
        'uogonek' => '676',                      # U+0x0173
        'Wcircumflex' => '1126',                 # U+0x0174
        'wcircumflex' => '863',                  # U+0x0175
        'Ycircumflex' => '731',                  # U+0x0176
        'ycircumflex' => '562',                  # U+0x0177
        'Zacute' => '689',                       # U+0x0179
        'zacute' => '525',                       # U+0x017A
        'Zdotaccent' => '689',                   # U+0x017B
        'zdotaccent' => '525',                   # U+0x017C
        'longs' => '353',                        # U+0x017F
        'Aringacute' => '758',                   # U+0x01FA
        'aringacute' => '595',                   # U+0x01FB
        'AEacute' => '1069',                     # U+0x01FC
        'aeacute' => '857',                      # U+0x01FD
        'Oslashacute' => '819',                  # U+0x01FE
        'oslashacute' => '635',                  # U+0x01FF
        'Scommaaccent' => '648',                 # U+0x0218
        'scommaaccent' => '512',                 # U+0x0219
        'caron' => '500',                        # U+0x02C7
        'breve' => '500',                        # U+0x02D8
        'dotaccent' => '500',                    # U+0x02D9
        'ring' => '500',                         # U+0x02DA
        'ogonek' => '500',                       # U+0x02DB
        'hungarumlaut' => '500',                 # U+0x02DD
        'dblgravecmb' => '500',                  # U+0x030F
        'tonos' => '500',                        # U+0x0384
        'dieresistonos' => '500',                # U+0x0385
        'Alphatonos' => '758',                   # U+0x0386
        'anoteleia' => '367',                    # U+0x0387
        'Epsilontonos' => '880',                 # U+0x0388
        'Etatonos' => '1072',                    # U+0x0389
        'Iotatonos' => '604',                    # U+0x038A
        'Omicrontonos' => '922',                 # U+0x038C
        'Upsilontonos' => '935',                 # U+0x038E
        'Omegatonos' => '960',                   # U+0x038F
        'iotadieresistonos' => '342',            # U+0x0390
        'Alpha' => '758',                        # U+0x0391
        'Beta' => '757',                         # U+0x0392
        'Gamma' => '657',                        # U+0x0393
        'Delta' => '739',                        # U+0x0394
        'Epsilon' => '721',                      # U+0x0395
        'Zeta' => '689',                         # U+0x0396
        'Eta' => '913',                          # U+0x0397
        'Theta' => '822',                        # U+0x0398
        'Iota' => '445',                         # U+0x0399
        'Kappa' => '816',                        # U+0x039A
        'Lambda' => '752',                       # U+0x039B
        'Mu' => '1023',                          # U+0x039C
        'Nu' => '839',                           # U+0x039D
        'Xi' => '766',                           # U+0x039E
        'Omicron' => '819',                      # U+0x039F
        'Pi' => '900',                           # U+0x03A0
        'Rho' => '701',                          # U+0x03A1
        'Sigma' => '679',                        # U+0x03A3
        'Tau' => '684',                          # U+0x03A4
        'Upsilon' => '731',                      # U+0x03A5
        'Phi' => '911',                          # U+0x03A6
        'Chi' => '808',                          # U+0x03A7
        'Psi' => '1011',                         # U+0x03A8
        'Omega' => '874',                        # U+0x03A9
        'Iotadieresis' => '445',                 # U+0x03AA
        'Upsilondieresis' => '731',              # U+0x03AB
        'alphatonos' => '679',                   # U+0x03AC
        'epsilontonos' => '535',                 # U+0x03AD
        'etatonos' => '660',                     # U+0x03AE
        'iotatonos' => '342',                    # U+0x03AF
        'upsilondieresistonos' => '592',         # U+0x03B0
        'alpha' => '679',                        # U+0x03B1
        'beta' => '656',                         # U+0x03B2
        'gamma' => '570',                        # U+0x03B3
        'delta' => '635',                        # U+0x03B4
        'epsilon' => '535',                      # U+0x03B5
        'zeta' => '462',                         # U+0x03B6
        'eta' => '660',                          # U+0x03B7
        'theta' => '640',                        # U+0x03B8
        'iota' => '342',                         # U+0x03B9
        'kappa' => '630',                        # U+0x03BA
        'lambda' => '527',                       # U+0x03BB
        'nu' => '561',                           # U+0x03BD
        'xi' => '498',                           # U+0x03BE
        'omicron' => '635',                      # U+0x03BF
        'pi' => '659',                           # U+0x03C0
        'rho' => '646',                          # U+0x03C1
        'sigma1' => '513',                       # U+0x03C2
        'sigma' => '669',                        # U+0x03C3
        'tau' => '485',                          # U+0x03C4
        'upsilon' => '592',                      # U+0x03C5
        'phi' => '823',                          # U+0x03C6
        'chi' => '566',                          # U+0x03C7
        'psi' => '840',                          # U+0x03C8
        'omega' => '812',                        # U+0x03C9
        'iotadieresis' => '342',                 # U+0x03CA
        'upsilondieresis' => '592',              # U+0x03CB
        'omicrontonos' => '635',                 # U+0x03CC
        'upsilontonos' => '592',                 # U+0x03CD
        'omegatonos' => '812',                   # U+0x03CE
        'afii10023' => '721',                    # U+0x0401
        'afii10051' => '883',                    # U+0x0402
        'afii10052' => '657',                    # U+0x0403
        'afii10053' => '733',                    # U+0x0404
        'afii10054' => '648',                    # U+0x0405
        'afii10055' => '445',                    # U+0x0406
        'afii10056' => '445',                    # U+0x0407
        'afii10057' => '595',                    # U+0x0408
        'afii10058' => '1124',                   # U+0x0409
        'afii10059' => '1197',                   # U+0x040A
        'afii10060' => '935',                    # U+0x040B
        'afii10061' => '799',                    # U+0x040C
        'afii10062' => '727',                    # U+0x040E
        'afii10145' => '901',                    # U+0x040F
        'afii10017' => '758',                    # U+0x0410
        'afii10018' => '747',                    # U+0x0411
        'afii10019' => '757',                    # U+0x0412
        'afii10020' => '657',                    # U+0x0413
        'afii10021' => '800',                    # U+0x0414
        'afii10022' => '721',                    # U+0x0415
        'afii10024' => '1129',                   # U+0x0416
        'afii10025' => '676',                    # U+0x0417
        'afii10026' => '921',                    # U+0x0418
        'afii10027' => '921',                    # U+0x0419
        'afii10028' => '799',                    # U+0x041A
        'afii10029' => '834',                    # U+0x041B
        'afii10030' => '1023',                   # U+0x041C
        'afii10031' => '913',                    # U+0x041D
        'afii10032' => '819',                    # U+0x041E
        'afii10033' => '900',                    # U+0x041F
        'afii10034' => '701',                    # U+0x0420
        'afii10035' => '715',                    # U+0x0421
        'afii10036' => '684',                    # U+0x0422
        'afii10037' => '727',                    # U+0x0423
        'afii10038' => '911',                    # U+0x0424
        'afii10039' => '808',                    # U+0x0425
        'afii10040' => '901',                    # U+0x0426
        'afii10041' => '832',                    # U+0x0427
        'afii10042' => '1288',                   # U+0x0428
        'afii10043' => '1288',                   # U+0x0429
        'afii10044' => '863',                    # U+0x042A
        'afii10045' => '1103',                   # U+0x042B
        'afii10046' => '733',                    # U+0x042C
        'afii10047' => '729',                    # U+0x042D
        'afii10048' => '1181',                   # U+0x042E
        'afii10049' => '792',                    # U+0x042F
        'afii10065' => '595',                    # U+0x0430
        'afii10066' => '625',                    # U+0x0431
        'afii10067' => '619',                    # U+0x0432
        'afii10068' => '497',                    # U+0x0433
        'afii10069' => '615',                    # U+0x0434
        'afii10070' => '571',                    # U+0x0435
        'afii10072' => '891',                    # U+0x0436
        'afii10073' => '539',                    # U+0x0437
        'afii10074' => '717',                    # U+0x0438
        'afii10075' => '717',                    # U+0x0439
        'afii10076' => '640',                    # U+0x043A
        'afii10077' => '656',                    # U+0x043B
        'afii10078' => '802',                    # U+0x043C
        'afii10079' => '709',                    # U+0x043D
        'afii10080' => '635',                    # U+0x043E
        'afii10081' => '699',                    # U+0x043F
        'afii10082' => '657',                    # U+0x0440
        'afii10083' => '531',                    # U+0x0441
        'afii10084' => '545',                    # U+0x0442
        'afii10085' => '562',                    # U+0x0443
        'afii10086' => '875',                    # U+0x0444
        'afii10087' => '587',                    # U+0x0445
        'afii10088' => '702',                    # U+0x0446
        'afii10089' => '666',                    # U+0x0447
        'afii10090' => '989',                    # U+0x0448
        'afii10091' => '992',                    # U+0x0449
        'afii10092' => '680',                    # U+0x044A
        'afii10093' => '915',                    # U+0x044B
        'afii10094' => '592',                    # U+0x044C
        'afii10095' => '546',                    # U+0x044D
        'afii10096' => '937',                    # U+0x044E
        'afii10097' => '639',                    # U+0x044F
        'afii10071' => '571',                    # U+0x0451
        'afii10099' => '670',                    # U+0x0452
        'afii10100' => '497',                    # U+0x0453
        'afii10101' => '558',                    # U+0x0454
        'afii10102' => '512',                    # U+0x0455
        'afii10103' => '353',                    # U+0x0456
        'afii10104' => '353',                    # U+0x0457
        'afii10105' => '346',                    # U+0x0458
        'afii10106' => '882',                    # U+0x0459
        'afii10107' => '932',                    # U+0x045A
        'afii10108' => '679',                    # U+0x045B
        'afii10109' => '640',                    # U+0x045C
        'afii10110' => '562',                    # U+0x045E
        'afii10193' => '699',                    # U+0x045F
        'afii10050' => '649',                    # U+0x0490
        'afii10098' => '495',                    # U+0x0491
        'Wgrave' => '1126',                      # U+0x1E80
        'wgrave' => '863',                       # U+0x1E81
        'Wacute' => '1126',                      # U+0x1E82
        'wacute' => '863',                       # U+0x1E83
        'Wdieresis' => '1126',                   # U+0x1E84
        'wdieresis' => '863',                    # U+0x1E85
        'Ygrave' => '731',                       # U+0x1EF2
        'ygrave' => '562',                       # U+0x1EF3
        'afii00208' => '927',                    # U+0x2015
        'underscoredbl' => '703',                # U+0x2017
        'quotereversed' => '268',                # U+0x201B
        'minute' => '321',                       # U+0x2032
        'second' => '532',                       # U+0x2033
        'exclamdbl' => '664',                    # U+0x203C
        'fraction' => '94',                      # U+0x2044
        'foursuperior' => '551',                 # U+0x2074
        'fivesuperior' => '551',                 # U+0x2075
        'sevensuperior' => '551',                # U+0x2077
        'eightsuperior' => '551',                # U+0x2078
        'nsuperior' => '588',                    # U+0x207F
        'franc' => '689',                        # U+0x20A3
        'lira' => '689',                         # U+0x20A4
        'peseta' => '1355',                      # U+0x20A7
        'afii61248' => '879',                    # U+0x2105
        'afii61289' => '323',                    # U+0x2113
        'afii61352' => '1279',                   # U+0x2116
        'estimated' => '649',                    # U+0x212E
        'oneeighth' => '1071',                   # U+0x215B
        'threeeighths' => '1071',                # U+0x215C
        'fiveeighths' => '1071',                 # U+0x215D
        'seveneighths' => '1071',                # U+0x215E
        'partialdiff' => '646',                  # U+0x2202
        'product' => '932',                      # U+0x220F
        'summation' => '729',                    # U+0x2211
        'minus' => '703',                        # U+0x2212
        'radical' => '716',                      # U+0x221A
        'infinity' => '798',                     # U+0x221E
        'integral' => '627',                     # U+0x222B
        'approxequal' => '703',                  # U+0x2248
        'notequal' => '703',                     # U+0x2260
        'lessequal' => '703',                    # U+0x2264
        'greaterequal' => '703',                 # U+0x2265
        'H22073' => '604',                       # U+0x25A1
        'H18543' => '354',                       # U+0x25AA
        'H18551' => '354',                       # U+0x25AB
        'lozenge' => '717',                      # U+0x25CA
        'H18533' => '604',                       # U+0x25CF
        'openbullet' => '354',                   # U+0x25E6
        'commaaccent' => '500',                  # U+0xF6C3
        'Acute' => '500',                        # U+0xF6C9
        'Caron' => '500',                        # U+0xF6CA
        'Dieresis' => '500',                     # U+0xF6CB
        'Grave' => '500',                        # U+0xF6CE
        'Hungarumlaut' => '500',                 # U+0xF6CF
        'radicalex' => '703',                    # U+0xF8E5
        'fi' => '694',                           # U+0xFB01
        'fl' => '705',                           # U+0xFB02
    }, # HORIZ. WIDTH TABLE
} };

1;
