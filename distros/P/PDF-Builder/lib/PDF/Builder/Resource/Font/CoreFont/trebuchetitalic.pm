package PDF::Builder::Resource::Font::CoreFont::trebuchetitalic;

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::Font::CoreFont::trebuchetitalic - Font-specific information for italic Trebuchet font

I<Not> a standard PDF core font

=cut

sub data { return {
    'fontname' => 'TrebuchetMS,Italic',
    'type' => 'TrueType',
    'apiname' => 'TrIt',
    'ascender' => '938',
    'capheight' => '715',
    'descender' => '-222',
    'isfixedpitch' => '0',
    'issymbol' => '0',
    'italicangle' => '-10',
    'underlineposition' => '-261',
    'underlinethickness' => '127',
    'xheight' => '522',
    'firstchar' => '32',
    'lastchar' => '255',
    'flags' => '104',
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
    'fontbbox' => [ -109, -257, 1107, 945 ],
# source: \Windows\Fonts\trebucit.ttf
# font underline position = -261
# CIDs 0 .. 1167 to be output
# fontbbox = (-449 -257 1362 965)
    'wx' => { # HORIZ. WIDTH TABLE
        'A'       => 610,
        'AE'       => 866,
        'AEacute'       => 866,
        'Aacute'       => 610,
        'Abreve'       => 610,
        'Acircumflex'       => 610,
        'Adieresis'       => 610,
        'Agrave'       => 610,
        'Alpha'       => 610,
        'Alphatonos'       => 610,
        'Amacron'       => 610,
        'Aogonek'       => 610,
        'Aring'       => 610,
        'Aringacute'       => 610,
        'Atilde'       => 610,
        'Aybarmenian'       => 672,
        'B'       => 565,
        'Benarmenian'       => 647,
        'Beta'       => 565,
        'C'       => 598,
        'Caarmenian'       => 706,
        'Cacute'       => 598,
        'Ccaron'       => 598,
        'Ccedilla'       => 598,
        'Ccircumflex'       => 598,
        'Cdotaccent'       => 598,
        'Chaarmenian'       => 653,
        'Cheharmenian'       => 687,
        'Chi'       => 557,
        'Coarmenian'       => 663,
        'D'       => 613,
        'Daarmenian'       => 661,
        'Dcaron'       => 613,
        'Dcroat'       => 613,
        'Delta'       => 584,
        'E'       => 535,
        'Eacute'       => 535,
        'Ebreve'       => 535,
        'Ecaron'       => 535,
        'Echarmenian'       => 639,
        'Ecircumflex'       => 535,
        'Edieresis'       => 535,
        'Edotaccent'       => 535,
        'Egrave'       => 535,
        'Eharmenian'       => 603,
        'Emacron'       => 535,
        'Eng'       => 651,
        'Eogonek'       => 535,
        'Epsilon'       => 536,
        'Epsilontonos'       => 645,
        'Eta'       => 653,
        'Etarmenian'       => 647,
        'Etatonos'       => 753,
        'Eth'       => 613,
        'Euro'       => 524,
        'F'       => 524,
        'Feharmenian'       => 776,
        'G'       => 676,
        'Gamma'       => 515,
        'Gbreve'       => 676,
        'Gcircumflex'       => 676,
        'Gcommaaccent'       => 676,
        'Gdotaccent'       => 676,
        'Ghadarmenian'       => 661,
        'Gimarmenian'       => 668,
        'H'       => 654,
        'H18533'       => 604,
        'H18543'       => 354,
        'H18551'       => 354,
        'H22073'       => 604,
        'Hbar'       => 682,
        'Hcircumflex'       => 654,
        'Hoarmenian'       => 563,
        'I'       => 278,
        'IJ'       => 727,
        'Iacute'       => 278,
        'Ibreve'       => 278,
        'Icircumflex'       => 278,
        'Idieresis'       => 278,
        'Idotaccent'       => 278,
        'Igrave'       => 278,
        'Imacron'       => 278,
        'Iniarmenian'       => 617,
        'Iogonek'       => 278,
        'Iota'       => 277,
        'Iotadieresis'       => 277,
        'Iotatonos'       => 375,
        'Itilde'       => 278,
        'J'       => 476,
        'Jaarmenian'       => 687,
        'Jcircumflex'       => 476,
        'Jheharmenian'       => 684,
        'K'       => 575,
        'Kappa'       => 576,
        'Kcommaaccent'       => 575,
        'Keharmenian'       => 675,
        'Kenarmenian'       => 640,
        'L'       => 506,
        'Lacute'       => 506,
        'Lambda'       => 587,
        'Lcaron'       => 506,
        'Lcommaaccent'       => 506,
        'Ldot'       => 506,
        'Liwnarmenian'       => 506,
        'Lslash'       => 506,
        'M'       => 761,
        'Menarmenian'       => 684,
        'Mu'       => 761,
        'N'       => 638,
        'Nacute'       => 638,
        'Ncaron'       => 638,
        'Ncommaaccent'       => 638,
        'Nowarmenian'       => 662,
        'Ntilde'       => 638,
        'Nu'       => 638,
        'O'       => 673,
        'OE'       => 993,
        'Oacute'       => 673,
        'Obreve'       => 673,
        'Ocircumflex'       => 673,
        'Odieresis'       => 673,
        'Ograve'       => 673,
        'Oharmenian'       => 677,
        'Ohungarumlaut'       => 673,
        'Omacron'       => 673,
        'Omega'       => 668,
        'Omegatonos'       => 758,
        'Omicron'       => 673,
        'Omicrontonos'       => 733,
        'Oslash'       => 673,
        'Oslashacute'       => 673,
        'Otilde'       => 673,
        'P'       => 543,
        'Peharmenian'       => 794,
        'Phi'       => 766,
        'Pi'       => 636,
        'Piwrarmenian'       => 806,
        'Psi'       => 758,
        'Q'       => 673,
        'R'       => 582,
        'Raarmenian'       => 690,
        'Racute'       => 582,
        'Rcaron'       => 582,
        'Rcommaaccent'       => 582,
        'Reharmenian'       => 623,
        'Rho'       => 542,
        'S'       => 480,
        'Sacute'       => 480,
        'Scaron'       => 480,
        'Scedilla'       => 480,
        'Scircumflex'       => 480,
        'Scommaaccent'       => 480,
        'Seharmenian'       => 648,
        'Shaarmenian'       => 651,
        'Sigma'       => 541,
        'T'       => 580,
        'Tau'       => 581,
        'Tbar'       => 580,
        'Tcaron'       => 580,
        'Tcedilla'       => 580,
        'Tcommaaccent'       => 580,
        'Theta'       => 690,
        'Thorn'       => 543,
        'Tiwnarmenian'       => 643,
        'Toarmenian'       => 837,
        'U'       => 648,
        'Uacute'       => 648,
        'Ubreve'       => 648,
        'Ucircumflex'       => 648,
        'Udieresis'       => 648,
        'Ugrave'       => 648,
        'Uhungarumlaut'       => 648,
        'Umacron'       => 648,
        'Uogonek'       => 648,
        'Upsilon'       => 569,
        'Upsilondieresis'       => 569,
        'Upsilontonos'       => 713,
        'Uring'       => 648,
        'Utilde'       => 648,
        'V'       => 587,
        'Vewarmenian'       => 661,
        'Voarmenian'       => 648,
        'W'       => 852,
        'Wacute'       => 852,
        'Wcircumflex'       => 852,
        'Wdieresis'       => 852,
        'Wgrave'       => 852,
        'X'       => 556,
        'Xeharmenian'       => 862,
        'Xi'       => 602,
        'Y'       => 570,
        'Yacute'       => 570,
        'Ycircumflex'       => 570,
        'Ydieresis'       => 570,
        'Ygrave'       => 570,
        'Yiarmenian'       => 648,
        'Yiwnarmenian'       => 511,
        'Z'       => 550,
        'Zaarmenian'       => 683,
        'Zacute'       => 550,
        'Zcaron'       => 550,
        'Zdotaccent'       => 550,
        'Zeta'       => 549,
        'Zhearmenian'       => 677,
        'a'       => 525,
        'aacute'       => 525,
        'abbreviationmarkarmenian'       => 0,
        'abreve'       => 525,
        'acircumflex'       => 525,
        'acute'       => 524,
        'adieresis'       => 525,
        'ae'       => 844,
        'aeacute'       => 844,
        'afii00208'       => 734,
        'afii10017'       => 610,
        'afii10018'       => 569,
        'afii10019'       => 569,
        'afii10020'       => 519,
        'afii10021'       => 684,
        'afii10022'       => 546,
        'afii10023'       => 546,
        'afii10024'       => 888,
        'afii10025'       => 518,
        'afii10026'       => 670,
        'afii10027'       => 670,
        'afii10028'       => 608,
        'afii10029'       => 674,
        'afii10030'       => 751,
        'afii10031'       => 653,
        'afii10032'       => 674,
        'afii10033'       => 636,
        'afii10034'       => 561,
        'afii10035'       => 563,
        'afii10036'       => 619,
        'afii10037'       => 580,
        'afii10038'       => 749,
        'afii10039'       => 575,
        'afii10040'       => 645,
        'afii10041'       => 596,
        'afii10042'       => 891,
        'afii10043'       => 908,
        'afii10044'       => 742,
        'afii10045'       => 772,
        'afii10046'       => 576,
        'afii10047'       => 567,
        'afii10048'       => 890,
        'afii10049'       => 598,
        'afii10050'       => 519,
        'afii10051'       => 721,
        'afii10052'       => 519,
        'afii10053'       => 565,
        'afii10054'       => 477,
        'afii10055'       => 277,
        'afii10056'       => 277,
        'afii10057'       => 466,
        'afii10058'       => 980,
        'afii10059'       => 915,
        'afii10060'       => 745,
        'afii10061'       => 611,
        'afii10062'       => 580,
        'afii10065'       => 539,
        'afii10066'       => 578,
        'afii10067'       => 539,
        'afii10068'       => 454,
        'afii10069'       => 584,
        'afii10070'       => 513,
        'afii10071'       => 513,
        'afii10072'       => 736,
        'afii10073'       => 452,
        'afii10074'       => 568,
        'afii10075'       => 568,
        'afii10076'       => 522,
        'afii10077'       => 581,
        'afii10078'       => 735,
        'afii10079'       => 563,
        'afii10080'       => 541,
        'afii10081'       => 555,
        'afii10082'       => 559,
        'afii10083'       => 456,
        'afii10084'       => 840,
        'afii10085'       => 504,
        'afii10086'       => 751,
        'afii10087'       => 514,
        'afii10088'       => 589,
        'afii10089'       => 544,
        'afii10090'       => 834,
        'afii10091'       => 863,
        'afii10092'       => 645,
        'afii10093'       => 736,
        'afii10094'       => 536,
        'afii10095'       => 458,
        'afii10096'       => 732,
        'afii10097'       => 527,
        'afii10098'       => 438,
        'afii10099'       => 550,
        'afii10100'       => 454,
        'afii10101'       => 456,
        'afii10102'       => 412,
        'afii10103'       => 290,
        'afii10104'       => 290,
        'afii10105'       => 300,
        'afii10106'       => 865,
        'afii10107'       => 806,
        'afii10108'       => 550,
        'afii10109'       => 522,
        'afii10110'       => 504,
        'afii10145'       => 638,
        'afii10193'       => 566,
        'afii61248'       => 698,
        'afii61289'       => 524,
        'afii61352'       => 894,
        'agrave'       => 525,
        'alpha'       => 546,
        'alphatonos'       => 546,
        'amacron'       => 525,
        'ampersand'       => 706,
        'anoteleia'       => 367,
        'aogonek'       => 525,
        'apostrophearmenian'       => 367,
        'approxequal'       => 524,
        'aring'       => 525,
        'aringacute'       => 525,
        'asciicircum'       => 524,
        'asciitilde'       => 524,
        'asterisk'       => 367,
        'at'       => 770,
        'atilde'       => 525,
        'aybarmenian'       => 822,
        'b'       => 557,
        'backslash'       => 355,
        'bar'       => 524,
        'benarmenian'       => 548,
        'beta'       => 563,
        'braceleft'       => 367,
        'braceright'       => 367,
        'bracketleft'       => 367,
        'bracketright'       => 367,
        'breve'       => 524,
        'brokenbar'       => 524,
        'bullet'       => 524,
        'c'       => 459,
        'caarmenian'       => 537,
        'cacute'       => 459,
        'caron'       => 524,
        'ccaron'       => 459,
        'ccedilla'       => 459,
        'ccircumflex'       => 459,
        'cdotaccent'       => 459,
        'cedilla'       => 524,
        'cent'       => 524,
        'chaarmenian'       => 354,
        'cheharmenian'       => 534,
        'chi'       => 514,
        'circumflex'       => 524,
        'coarmenian'       => 557,
        'colon'       => 367,
        'comma'       => 367,
        'commaarmenian'       => 221,
        'copyright'       => 712,
        'currency'       => 524,
        'd'       => 557,
        'daarmenian'       => 578,
        'dagger'       => 458,
        'daggerdbl'       => 458,
        'dcaron'       => 691,
        'dcroat'       => 557,
        'degree'       => 524,
        'delta'       => 546,
        'dieresis'       => 524,
        'dieresistonos'       => 523,
        'divide'       => 524,
        'dollar'       => 480,
        'dotaccent'       => 524,
        'dotlessi'       => 306,
        'e'       => 537,
        'eacute'       => 537,
        'ebreve'       => 537,
        'ecaron'       => 537,
        'echarmenian'       => 537,
        'echyiwnarmenian'       => 717,
        'ecircumflex'       => 537,
        'edieresis'       => 537,
        'edotaccent'       => 537,
        'egrave'       => 537,
        'eharmenian'       => 466,
        'eight'       => 524,
        'eightinferior'       => 379,
        'eightsuperior'       => 379,
        'ellipsis'       => 734,
        'emacron'       => 537,
        'emdash'       => 734,
        'emphasismarkarmenian'       => 166,
        'endash'       => 367,
        'eng'       => 546,
        'eogonek'       => 537,
        'epsilon'       => 464,
        'epsilontonos'       => 464,
        'equal'       => 524,
        'estimated'       => 549,
        'eta'       => 553,
        'etarmenian'       => 546,
        'etatonos'       => 553,
        'eth'       => 549,
        'exclam'       => 367,
        'exclamarmenian'       => 205,
        'exclamdbl'       => 609,
        'exclamdown'       => 367,
        'f'       => 401,
        'feharmenian'       => 757,
        'ff'       => 599,
        'ffi'       => 875,
        'ffl'       => 863,
        'fi'       => 636,
        'five'       => 524,
        'fiveeighths'       => 814,
        'fiveinferior'       => 379,
        'fivesuperior'       => 379,
        'fl'       => 672,
        'florin'       => 401,
        'four'       => 524,
        'fourinferior'       => 379,
        'foursuperior'       => 379,
        'fraction'       => 528,
        'franc'       => 941,
        'g'       => 501,
        'gamma'       => 525,
        'gbreve'       => 501,
        'gcircumflex'       => 501,
        'gcommaaccent'       => 501,
        'gdotaccent'       => 501,
        'germandbls'       => 546,
        'ghadarmenian'       => 546,
        'gimarmenian'       => 581,
        'grave'       => 524,
        'greater'       => 524,
        'greaterequal'       => 524,
        'guillemotleft'       => 524,
        'guillemotright'       => 524,
        'guilsinglleft'       => 367,
        'guilsinglright'       => 367,
        'h'       => 557,
        'hbar'       => 553,
        'hcircumflex'       => 557,
        'hoarmenian'       => 537,
        'hungarumlaut'       => 524,
        'hyphen'       => 367,
        'hyphentwo'       => 367,
        'i'       => 306,
        'iacute'       => 306,
        'ibreve'       => 306,
        'icircumflex'       => 306,
        'idieresis'       => 306,
        'igrave'       => 306,
        'ij'       => 585,
        'imacron'       => 306,
        'infinity'       => 524,
        'iniarmenian'       => 536,
        'integral'       => 524,
        'iogonek'       => 306,
        'iota'       => 269,
        'iotadieresis'       => 269,
        'iotadieresistonos'       => 269,
        'iotatonos'       => 269,
        'itilde'       => 306,
        'j'       => 366,
        'jaarmenian'       => 527,
        'jcircumflex'       => 366,
        'jheharmenian'       => 529,
        'k'       => 504,
        'kappa'       => 537,
        'kcommaaccent'       => 504,
        'keharmenian'       => 600,
        'kenarmenian'       => 539,
        'kgreenlandic'       => 537,
        'l'       => 320,
        'lacute'       => 320,
        'lambda'       => 527,
        'lcaron'       => 320,
        'lcommaaccent'       => 320,
        'ldot'       => 506,
        'less'       => 524,
        'lessequal'       => 524,
        'lira'       => 529,
        'liwnarmenian'       => 229,
        'logicalnot'       => 524,
        'longs'       => 349,
        'lozenge'       => 494,
        'lslash'       => 294,
        'm'       => 830,
        'macron'       => 524,
        'menarmenian'       => 539,
        'minus'       => 524,
        'minute'       => 159,
        'mu'       => 556,
        'multiply'       => 524,
        'n'       => 546,
        'nacute'       => 546,
        'napostrophe'       => 604,
        'ncaron'       => 546,
        'ncommaaccent'       => 546,
        'nine'       => 524,
        'nineinferior'       => 379,
        'ninesuperior'       => 379,
        'notequal'       => 524,
        'nowarmenian'       => 539,
        'nsuperior'       => 451,
        'ntilde'       => 546,
        'nu'       => 500,
        'numbersign'       => 524,
        'o'       => 536,
        'oacute'       => 536,
        'obreve'       => 536,
        'ocircumflex'       => 536,
        'odieresis'       => 536,
        'oe'       => 891,
        'ogonek'       => 524,
        'ograve'       => 536,
        'oharmenian'       => 536,
        'ohungarumlaut'       => 536,
        'omacron'       => 536,
        'omega'       => 762,
        'omegatonos'       => 762,
        'omicron'       => 543,
        'omicrontonos'       => 543,
        'one'       => 524,
        'oneeighth'       => 814,
        'onehalf'       => 814,
        'oneinferior'       => 379,
        'onequarter'       => 814,
        'onesuperior'       => 451,
        'openbullet'       => 354,
        'ordfeminine'       => 452,
        'ordmasculine'       => 458,
        'oslash'       => 536,
        'oslashacute'       => 536,
        'otilde'       => 536,
        'overline'       => 524,
        'p'       => 557,
        'paragraph'       => 598,
        'parenleft'       => 367,
        'parenright'       => 367,
        'partialdiff'       => 549,
        'peharmenian'       => 822,
        'percent'       => 600,
        'period'       => 367,
        'periodarmenian'       => 367,
        'periodcentered'       => 367,
        'perthousand'       => 912,
        'peseta'       => 1109,
        'phi'       => 701,
        'pi'       => 601,
        'piwrarmenian'       => 810,
        'plus'       => 524,
        'plusminus'       => 524,
        'product'       => 552,
        'psi'       => 740,
        'q'       => 557,
        'question'       => 367,
        'questionarmenian'       => 253,
        'questiondown'       => 367,
        'questiongreek'       => 367,
        'quotedbl'       => 324,
        'quotedblbase'       => 524,
        'quotedblleft'       => 524,
        'quotedblright'       => 524,
        'quoteleft'       => 367,
        'quotereversed'       => 367,
        'quoteright'       => 367,
        'quotesinglbase'       => 367,
        'quotesingle'       => 159,
        'r'       => 416,
        'raarmenian'       => 555,
        'racute'       => 416,
        'radical'       => 524,
        'rcaron'       => 416,
        'rcommaaccent'       => 416,
        'registered'       => 712,
        'reharmenian'       => 546,
        'rho'       => 577,
        'ring'       => 524,
        'ringhalfleftarmenian'       => 367,
        's'       => 404,
        'sacute'       => 404,
        'scaron'       => 404,
        'scedilla'       => 404,
        'scircumflex'       => 404,
        'scommaaccent'       => 404,
        'second'       => 338,
        'section'       => 453,
        'seharmenian'       => 539,
        'semicolon'       => 367,
        'seven'       => 524,
        'seveneighths'       => 814,
        'seveninferior'       => 379,
        'sevensuperior'       => 379,
        'shaarmenian'       => 407,
        'sigma'       => 575,
        'sigma1'       => 472,
        'six'       => 524,
        'sixinferior'       => 379,
        'sixsuperior'       => 379,
        'slash'       => 524,
        'space'       => 301,
        'sterling'       => 529,
        'summation'       => 524,
        't'       => 419,
        'tau'       => 432,
        'tbar'       => 419,
        'tcaron'       => 496,
        'tcedilla'       => 419,
        'tcommaaccent'       => 419,
        'theta'       => 565,
        'thorn'       => 557,
        'three'       => 524,
        'threeeighths'       => 814,
        'threeinferior'       => 379,
        'threequarters'       => 814,
        'threesuperior'       => 451,
        'tilde'       => 524,
        'tiwnarmenian'       => 810,
        'toarmenian'       => 698,
        'tonos'       => 523,
        'trademark'       => 634,
        'two'       => 524,
        'twoinferior'       => 379,
        'twosuperior'       => 451,
        'u'       => 556,
        'uacute'       => 556,
        'ubreve'       => 556,
        'ucircumflex'       => 556,
        'udieresis'       => 556,
        'ugrave'       => 556,
        'uhungarumlaut'       => 556,
        'umacron'       => 556,
        'underscore'       => 524,
        'underscoredbl'       => 523,
        'uni040D'       => 670,
        'uni045D'       => 568,
        'uni058A'       => 367,
        'uni058D'       => 912,
        'uni058E'       => 912,
        'uni058F'       => 693,
        'uni20B8'       => 524,
        'uni20B9'       => 524,
        'uni20BA'       => 524,
        'uni20BB'       => 644,
        'uni20BC'       => 732,
        'uni20BD'       => 524,
        'uni20BE'       => 747,
        'uniFB06'       => 772,
        'uniFB13'       => 1078,
        'uniFB14'       => 1076,
        'uniFB15'       => 1080,
        'uniFB16'       => 1078,
        'uniFB17'       => 1375,
        'uogonek'       => 556,
        'upsilon'       => 549,
        'upsilondieresis'       => 549,
        'upsilondieresistonos'       => 549,
        'upsilontonos'       => 549,
        'uring'       => 556,
        'utilde'       => 556,
        'v'       => 489,
        'vewarmenian'       => 539,
        'voarmenian'       => 546,
        'w'       => 744,
        'wacute'       => 744,
        'wcircumflex'       => 744,
        'wdieresis'       => 744,
        'wgrave'       => 744,
        'x'       => 500,
        'xeharmenian'       => 831,
        'xi'       => 454,
        'y'       => 493,
        'yacute'       => 493,
        'ycircumflex'       => 493,
        'ydieresis'       => 493,
        'yen'       => 556,
        'ygrave'       => 493,
        'yiarmenian'       => 225,
        'yiwnarmenian'       => 420,
        'z'       => 474,
        'zaarmenian'       => 560,
        'zacute'       => 474,
        'zcaron'       => 474,
        'zdotaccent'       => 474,
        'zero'       => 524,
        'zeroinferior'       => 379,
        'zerosuperior'       => 379,
        'zeta'       => 440,
        'zhearmenian'       => 587,
    },
    'wxold' => { # HORIZ. WIDTH TABLE
        'space' => '301',                        # C+0x20 # U+0x0020
        'exclam' => '367',                       # C+0x21 # U+0x0021
        'quotedbl' => '324',                     # C+0x22 # U+0x0022
        'numbersign' => '524',                   # C+0x23 # U+0x0023
        'dollar' => '480',                       # C+0x24 # U+0x0024
        'percent' => '600',                      # C+0x25 # U+0x0025
        'ampersand' => '706',                    # C+0x26 # U+0x0026
        'quotesingle' => '159',                  # C+0x27 # U+0x0027
        'parenleft' => '367',                    # C+0x28 # U+0x0028
        'parenright' => '367',                   # C+0x29 # U+0x0029
        'asterisk' => '367',                     # C+0x2A # U+0x002A
        'plus' => '524',                         # C+0x2B # U+0x002B
        'comma' => '367',                        # C+0x2C # U+0x002C
        'hyphen' => '367',                       # C+0x2D # U+0x002D
        'period' => '367',                       # C+0x2E # U+0x002E
        'slash' => '524',                        # C+0x2F # U+0x002F
        'zero' => '524',                         # C+0x30 # U+0x0030
        'one' => '524',                          # C+0x31 # U+0x0031
        'two' => '524',                          # C+0x32 # U+0x0032
        'three' => '524',                        # C+0x33 # U+0x0033
        'four' => '524',                         # C+0x34 # U+0x0034
        'five' => '524',                         # C+0x35 # U+0x0035
        'six' => '524',                          # C+0x36 # U+0x0036
        'seven' => '524',                        # C+0x37 # U+0x0037
        'eight' => '524',                        # C+0x38 # U+0x0038
        'nine' => '524',                         # C+0x39 # U+0x0039
        'colon' => '367',                        # C+0x3A # U+0x003A
        'semicolon' => '367',                    # C+0x3B # U+0x003B
        'less' => '524',                         # C+0x3C # U+0x003C
        'equal' => '524',                        # C+0x3D # U+0x003D
        'greater' => '524',                      # C+0x3E # U+0x003E
        'question' => '367',                     # C+0x3F # U+0x003F
        'at' => '770',                           # C+0x40 # U+0x0040
        'A' => '610',                            # C+0x41 # U+0x0041
        'B' => '565',                            # C+0x42 # U+0x0042
        'C' => '598',                            # C+0x43 # U+0x0043
        'D' => '613',                            # C+0x44 # U+0x0044
        'E' => '535',                            # C+0x45 # U+0x0045
        'F' => '524',                            # C+0x46 # U+0x0046
        'G' => '676',                            # C+0x47 # U+0x0047
        'H' => '654',                            # C+0x48 # U+0x0048
        'I' => '278',                            # C+0x49 # U+0x0049
        'J' => '476',                            # C+0x4A # U+0x004A
        'K' => '575',                            # C+0x4B # U+0x004B
        'L' => '506',                            # C+0x4C # U+0x004C
        'M' => '761',                            # C+0x4D # U+0x004D
        'N' => '638',                            # C+0x4E # U+0x004E
        'O' => '673',                            # C+0x4F # U+0x004F
        'P' => '543',                            # C+0x50 # U+0x0050
        'Q' => '673',                            # C+0x51 # U+0x0051
        'R' => '582',                            # C+0x52 # U+0x0052
        'S' => '480',                            # C+0x53 # U+0x0053
        'T' => '580',                            # C+0x54 # U+0x0054
        'U' => '648',                            # C+0x55 # U+0x0055
        'V' => '587',                            # C+0x56 # U+0x0056
        'W' => '852',                            # C+0x57 # U+0x0057
        'X' => '556',                            # C+0x58 # U+0x0058
        'Y' => '570',                            # C+0x59 # U+0x0059
        'Z' => '550',                            # C+0x5A # U+0x005A
        'bracketleft' => '367',                  # C+0x5B # U+0x005B
        'backslash' => '355',                    # C+0x5C # U+0x005C
        'bracketright' => '367',                 # C+0x5D # U+0x005D
        'asciicircum' => '524',                  # C+0x5E # U+0x005E
        'underscore' => '524',                   # C+0x5F # U+0x005F
        'grave' => '524',                        # C+0x60 # U+0x0060
        'a' => '525',                            # C+0x61 # U+0x0061
        'b' => '557',                            # C+0x62 # U+0x0062
        'c' => '459',                            # C+0x63 # U+0x0063
        'd' => '557',                            # C+0x64 # U+0x0064
        'e' => '537',                            # C+0x65 # U+0x0065
        'f' => '401',                            # C+0x66 # U+0x0066
        'g' => '501',                            # C+0x67 # U+0x0067
        'h' => '557',                            # C+0x68 # U+0x0068
        'i' => '306',                            # C+0x69 # U+0x0069
        'j' => '366',                            # C+0x6A # U+0x006A
        'k' => '504',                            # C+0x6B # U+0x006B
        'l' => '320',                            # C+0x6C # U+0x006C
        'm' => '830',                            # C+0x6D # U+0x006D
        'n' => '546',                            # C+0x6E # U+0x006E
        'o' => '536',                            # C+0x6F # U+0x006F
        'p' => '557',                            # C+0x70 # U+0x0070
        'q' => '557',                            # C+0x71 # U+0x0071
        'r' => '416',                            # C+0x72 # U+0x0072
        's' => '404',                            # C+0x73 # U+0x0073
        't' => '419',                            # C+0x74 # U+0x0074
        'u' => '556',                            # C+0x75 # U+0x0075
        'v' => '489',                            # C+0x76 # U+0x0076
        'w' => '744',                            # C+0x77 # U+0x0077
        'x' => '500',                            # C+0x78 # U+0x0078
        'y' => '493',                            # C+0x79 # U+0x0079
        'z' => '474',                            # C+0x7A # U+0x007A
        'braceleft' => '367',                    # C+0x7B # U+0x007B
        'bar' => '524',                          # C+0x7C # U+0x007C
        'braceright' => '367',                   # C+0x7D # U+0x007D
        'asciitilde' => '524',                   # C+0x7E # U+0x007E
        'bullet' => '524',                       # C+0x7F # U+0x2022
        'Euro' => '524',                         # C+0x80 # U+0x20AC
        'quotesinglbase' => '367',               # C+0x82 # U+0x201A
        'florin' => '401',                       # C+0x83 # U+0x0192
        'quotedblbase' => '524',                 # C+0x84 # U+0x201E
        'ellipsis' => '734',                     # C+0x85 # U+0x2026
        'dagger' => '458',                       # C+0x86 # U+0x2020
        'daggerdbl' => '458',                    # C+0x87 # U+0x2021
        'circumflex' => '524',                   # C+0x88 # U+0x02C6
        'perthousand' => '912',                  # C+0x89 # U+0x2030
        'Scaron' => '480',                       # C+0x8A # U+0x0160
        'guilsinglleft' => '367',                # C+0x8B # U+0x2039
        'OE' => '993',                           # C+0x8C # U+0x0152
        'Zcaron' => '550',                       # C+0x8E # U+0x017D
        'quoteleft' => '367',                    # C+0x91 # U+0x2018
        'quoteright' => '367',                   # C+0x92 # U+0x2019
        'quotedblleft' => '524',                 # C+0x93 # U+0x201C
        'quotedblright' => '524',                # C+0x94 # U+0x201D
        'endash' => '367',                       # C+0x96 # U+0x2013
        'emdash' => '734',                       # C+0x97 # U+0x2014
        'tilde' => '524',                        # C+0x98 # U+0x02DC
        'trademark' => '634',                    # C+0x99 # U+0x2122
        'scaron' => '404',                       # C+0x9A # U+0x0161
        'guilsinglright' => '367',               # C+0x9B # U+0x203A
        'oe' => '891',                           # C+0x9C # U+0x0153
        'zcaron' => '474',                       # C+0x9E # U+0x017E
        'Ydieresis' => '570',                    # C+0x9F # U+0x0178
        'exclamdown' => '367',                   # C+0xA1 # U+0x00A1
        'cent' => '524',                         # C+0xA2 # U+0x00A2
        'sterling' => '529',                     # C+0xA3 # U+0x00A3
        'currency' => '524',                     # C+0xA4 # U+0x00A4
        'yen' => '556',                          # C+0xA5 # U+0x00A5
        'brokenbar' => '524',                    # C+0xA6 # U+0x00A6
        'section' => '453',                      # C+0xA7 # U+0x00A7
        'dieresis' => '524',                     # C+0xA8 # U+0x00A8
        'copyright' => '712',                    # C+0xA9 # U+0x00A9
        'ordfeminine' => '452',                  # C+0xAA # U+0x00AA
        'guillemotleft' => '524',                # C+0xAB # U+0x00AB
        'logicalnot' => '524',                   # C+0xAC # U+0x00AC
        'registered' => '712',                   # C+0xAE # U+0x00AE
        'macron' => '524',                       # C+0xAF # U+0x00AF
        'degree' => '524',                       # C+0xB0 # U+0x00B0
        'plusminus' => '524',                    # C+0xB1 # U+0x00B1
        'twosuperior' => '451',                  # C+0xB2 # U+0x00B2
        'threesuperior' => '451',                # C+0xB3 # U+0x00B3
        'acute' => '524',                        # C+0xB4 # U+0x00B4
        'mu' => '556',                           # C+0xB5 # U+0x00B5
        'paragraph' => '598',                    # C+0xB6 # U+0x00B6
        'periodcentered' => '367',               # C+0xB7 # U+0x00B7
        'cedilla' => '524',                      # C+0xB8 # U+0x00B8
        'onesuperior' => '451',                  # C+0xB9 # U+0x00B9
        'ordmasculine' => '458',                 # C+0xBA # U+0x00BA
        'guillemotright' => '524',               # C+0xBB # U+0x00BB
        'onequarter' => '814',                   # C+0xBC # U+0x00BC
        'onehalf' => '814',                      # C+0xBD # U+0x00BD
        'threequarters' => '814',                # C+0xBE # U+0x00BE
        'questiondown' => '367',                 # C+0xBF # U+0x00BF
        'Agrave' => '610',                       # C+0xC0 # U+0x00C0
        'Aacute' => '610',                       # C+0xC1 # U+0x00C1
        'Acircumflex' => '610',                  # C+0xC2 # U+0x00C2
        'Atilde' => '610',                       # C+0xC3 # U+0x00C3
        'Adieresis' => '610',                    # C+0xC4 # U+0x00C4
        'Aring' => '610',                        # C+0xC5 # U+0x00C5
        'AE' => '866',                           # C+0xC6 # U+0x00C6
        'Ccedilla' => '598',                     # C+0xC7 # U+0x00C7
        'Egrave' => '535',                       # C+0xC8 # U+0x00C8
        'Eacute' => '535',                       # C+0xC9 # U+0x00C9
        'Ecircumflex' => '535',                  # C+0xCA # U+0x00CA
        'Edieresis' => '535',                    # C+0xCB # U+0x00CB
        'Igrave' => '278',                       # C+0xCC # U+0x00CC
        'Iacute' => '278',                       # C+0xCD # U+0x00CD
        'Icircumflex' => '278',                  # C+0xCE # U+0x00CE
        'Idieresis' => '278',                    # C+0xCF # U+0x00CF
        'Eth' => '613',                          # C+0xD0 # U+0x00D0
        'Ntilde' => '638',                       # C+0xD1 # U+0x00D1
        'Ograve' => '673',                       # C+0xD2 # U+0x00D2
        'Oacute' => '673',                       # C+0xD3 # U+0x00D3
        'Ocircumflex' => '673',                  # C+0xD4 # U+0x00D4
        'Otilde' => '673',                       # C+0xD5 # U+0x00D5
        'Odieresis' => '673',                    # C+0xD6 # U+0x00D6
        'multiply' => '524',                     # C+0xD7 # U+0x00D7
        'Oslash' => '673',                       # C+0xD8 # U+0x00D8
        'Ugrave' => '648',                       # C+0xD9 # U+0x00D9
        'Uacute' => '648',                       # C+0xDA # U+0x00DA
        'Ucircumflex' => '648',                  # C+0xDB # U+0x00DB
        'Udieresis' => '648',                    # C+0xDC # U+0x00DC
        'Yacute' => '570',                       # C+0xDD # U+0x00DD
        'Thorn' => '543',                        # C+0xDE # U+0x00DE
        'germandbls' => '546',                   # C+0xDF # U+0x00DF
        'agrave' => '525',                       # C+0xE0 # U+0x00E0
        'aacute' => '525',                       # C+0xE1 # U+0x00E1
        'acircumflex' => '525',                  # C+0xE2 # U+0x00E2
        'atilde' => '525',                       # C+0xE3 # U+0x00E3
        'adieresis' => '525',                    # C+0xE4 # U+0x00E4
        'aring' => '525',                        # C+0xE5 # U+0x00E5
        'ae' => '844',                           # C+0xE6 # U+0x00E6
        'ccedilla' => '459',                     # C+0xE7 # U+0x00E7
        'egrave' => '537',                       # C+0xE8 # U+0x00E8
        'eacute' => '537',                       # C+0xE9 # U+0x00E9
        'ecircumflex' => '537',                  # C+0xEA # U+0x00EA
        'edieresis' => '537',                    # C+0xEB # U+0x00EB
        'igrave' => '306',                       # C+0xEC # U+0x00EC
        'iacute' => '306',                       # C+0xED # U+0x00ED
        'icircumflex' => '306',                  # C+0xEE # U+0x00EE
        'idieresis' => '306',                    # C+0xEF # U+0x00EF
        'eth' => '549',                          # C+0xF0 # U+0x00F0
        'ntilde' => '546',                       # C+0xF1 # U+0x00F1
        'ograve' => '536',                       # C+0xF2 # U+0x00F2
        'oacute' => '536',                       # C+0xF3 # U+0x00F3
        'ocircumflex' => '536',                  # C+0xF4 # U+0x00F4
        'otilde' => '536',                       # C+0xF5 # U+0x00F5
        'odieresis' => '536',                    # C+0xF6 # U+0x00F6
        'divide' => '524',                       # C+0xF7 # U+0x00F7
        'oslash' => '536',                       # C+0xF8 # U+0x00F8
        'ugrave' => '556',                       # C+0xF9 # U+0x00F9
        'uacute' => '556',                       # C+0xFA # U+0x00FA
        'ucircumflex' => '556',                  # C+0xFB # U+0x00FB
        'udieresis' => '556',                    # C+0xFC # U+0x00FC
        'yacute' => '493',                       # C+0xFD # U+0x00FD
        'thorn' => '557',                        # C+0xFE # U+0x00FE
        'ydieresis' => '493',                    # C+0xFF # U+0x00FF
        'middot' => '367',                       # U+0x00B7
        'Amacron' => '610',                      # U+0x0100
        'amacron' => '525',                      # U+0x0101
        'Abreve' => '610',                       # U+0x0102
        'abreve' => '525',                       # U+0x0103
        'Aogonek' => '610',                      # U+0x0104
        'aogonek' => '525',                      # U+0x0105
        'Cacute' => '598',                       # U+0x0106
        'cacute' => '459',                       # U+0x0107
        'Ccircumflex' => '598',                  # U+0x0108
        'ccircumflex' => '459',                  # U+0x0109
        'Cdot' => '598',                         # U+0x010A
        'cdot' => '459',                         # U+0x010B
        'Ccaron' => '598',                       # U+0x010C
        'ccaron' => '459',                       # U+0x010D
        'Dcaron' => '613',                       # U+0x010E
        'dcaron' => '691',                       # U+0x010F
        'dcroat' => '557',                       # U+0x0111
        'Emacron' => '535',                      # U+0x0112
        'emacron' => '537',                      # U+0x0113
        'Ebreve' => '535',                       # U+0x0114
        'ebreve' => '537',                       # U+0x0115
        'Edot' => '535',                         # U+0x0116
        'edot' => '537',                         # U+0x0117
        'Eogonek' => '535',                      # U+0x0118
        'eogonek' => '537',                      # U+0x0119
        'Ecaron' => '535',                       # U+0x011A
        'ecaron' => '537',                       # U+0x011B
        'Gcircumflex' => '676',                  # U+0x011C
        'gcircumflex' => '501',                  # U+0x011D
        'Gbreve' => '676',                       # U+0x011E
        'gbreve' => '501',                       # U+0x011F
        'Gdot' => '676',                         # U+0x0120
        'gdot' => '501',                         # U+0x0121
        'Hcircumflex' => '654',                  # U+0x0124
        'hcircumflex' => '557',                  # U+0x0125
        'Hbar' => '682',                         # U+0x0126
        'hbar' => '553',                         # U+0x0127
        'Itilde' => '278',                       # U+0x0128
        'itilde' => '306',                       # U+0x0129
        'Imacron' => '278',                      # U+0x012A
        'imacron' => '306',                      # U+0x012B
        'Ibreve' => '278',                       # U+0x012C
        'ibreve' => '306',                       # U+0x012D
        'Iogonek' => '278',                      # U+0x012E
        'iogonek' => '306',                      # U+0x012F
        'Idotaccent' => '278',                   # U+0x0130
        'dotlessi' => '306',                     # U+0x0131
        'IJ' => '727',                           # U+0x0132
        'ij' => '585',                           # U+0x0133
        'Jcircumflex' => '476',                  # U+0x0134
        'jcircumflex' => '366',                  # U+0x0135
        'kgreenlandic' => '537',                 # U+0x0138
        'Lacute' => '506',                       # U+0x0139
        'lacute' => '320',                       # U+0x013A
        'Lcaron' => '506',                       # U+0x013D
        'lcaron' => '320',                       # U+0x013E
        'Ldot' => '506',                         # U+0x013F
        'ldot' => '506',                         # U+0x0140
        'Lslash' => '506',                       # U+0x0141
        'lslash' => '294',                       # U+0x0142
        'Nacute' => '638',                       # U+0x0143
        'nacute' => '546',                       # U+0x0144
        'Ncaron' => '638',                       # U+0x0147
        'ncaron' => '546',                       # U+0x0148
        'napostrophe' => '604',                  # U+0x0149
        'Eng' => '651',                          # U+0x014A
        'eng' => '546',                          # U+0x014B
        'Omacron' => '673',                      # U+0x014C
        'omacron' => '536',                      # U+0x014D
        'Obreve' => '673',                       # U+0x014E
        'obreve' => '536',                       # U+0x014F
        'Racute' => '582',                       # U+0x0154
        'racute' => '416',                       # U+0x0155
        'Rcaron' => '582',                       # U+0x0158
        'rcaron' => '416',                       # U+0x0159
        'Sacute' => '480',                       # U+0x015A
        'sacute' => '404',                       # U+0x015B
        'Scircumflex' => '480',                  # U+0x015C
        'scircumflex' => '404',                  # U+0x015D
        'Scedilla' => '480',                     # U+0x015E
        'scedilla' => '404',                     # U+0x015F
        'Tcaron' => '580',                       # U+0x0164
        'tcaron' => '496',                       # U+0x0165
        'Tbar' => '580',                         # U+0x0166
        'tbar' => '419',                         # U+0x0167
        'Utilde' => '648',                       # U+0x0168
        'utilde' => '556',                       # U+0x0169
        'Umacron' => '648',                      # U+0x016A
        'umacron' => '556',                      # U+0x016B
        'Ubreve' => '648',                       # U+0x016C
        'ubreve' => '556',                       # U+0x016D
        'Uring' => '648',                        # U+0x016E
        'uring' => '556',                        # U+0x016F
        'Uogonek' => '648',                      # U+0x0172
        'uogonek' => '556',                      # U+0x0173
        'Wcircumflex' => '852',                  # U+0x0174
        'wcircumflex' => '744',                  # U+0x0175
        'Ycircumflex' => '570',                  # U+0x0176
        'ycircumflex' => '493',                  # U+0x0177
        'Zacute' => '550',                       # U+0x0179
        'zacute' => '474',                       # U+0x017A
        'Zdot' => '550',                         # U+0x017B
        'zdot' => '474',                         # U+0x017C
        'caron' => '524',                        # U+0x02C7
        'breve' => '524',                        # U+0x02D8
        'dotaccent' => '524',                    # U+0x02D9
        'ring' => '524',                         # U+0x02DA
        'ogonek' => '524',                       # U+0x02DB
        'hungarumlaut' => '524',                 # U+0x02DD
        'dblgravecmb' => '524',                  # U+0x030F
        'Delta' => '584',                        # U+0x0394
        'Omega' => '668',                        # U+0x03A9
        'pi' => '601',                           # U+0x03C0
        'fraction' => '528',                     # U+0x2044
        'franc' => '941',                        # U+0x20A3
        'partialdiff' => '549',                  # U+0x2202
        'product' => '552',                      # U+0x220F
        'summation' => '524',                    # U+0x2211
        'minus' => '524',                        # U+0x2212
        'radical' => '524',                      # U+0x221A
        'infinity' => '524',                     # U+0x221E
        'integral' => '524',                     # U+0x222B
        'approxequal' => '524',                  # U+0x2248
        'notequal' => '524',                     # U+0x2260
        'lessequal' => '524',                    # U+0x2264
        'greaterequal' => '524',                 # U+0x2265
        'lozenge' => '494',                      # U+0x25CA
        'dotlessj' => '366',                     # U+0xF6BE
        'fi' => '636',                           # U+0xFB01
        'fl' => '672',                           # U+0xFB02
    }, # HORIZ. WIDTH TABLE
} };

1;
