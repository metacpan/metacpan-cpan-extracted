package PDF::Builder::Resource::Font::CoreFont::verdana;

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::Font::CoreFont::verdana - Font-specific information for regular Verdana font

I<Not> a standard PDF core font

=cut

sub data { return {
    'fontname' => 'Verdana',
    'type' => 'TrueType',
    'apiname' => 'Verd',
    'ascender' => '1005',
    'capheight' => '727',
    'descender' => '-209',
    'isfixedpitch' => '0',
    'issymbol' => '0',
    'italicangle' => '0',
    'underlineposition' => '-180',
    'underlinethickness' => '120',
    'xheight' => '545',
    'firstchar' => '32',
    'lastchar' => '255',
    'flags' => '40',
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
    'fontbbox' => [ -49, -206, 1446, 1000 ],
# source: \Windows\Fonts\verdana.ttf
# font underline position = -180
# CIDs 0 .. 1396 to be output
# fontbbox = (-559 -303 1522 1050)
    'wx' => { # HORIZ. WIDTH TABLE
        'A'       => 683,
        'AE'       => 984,
        'AEacute'       => 984,
        'Aacute'       => 683,
        'Abreve'       => 683,
        'Abreveacute'       => 683,
        'Abrevedotbelow'       => 683,
        'Abrevegrave'       => 683,
        'Abrevehookabove'       => 683,
        'Abrevetilde'       => 683,
        'Acircumflex'       => 683,
        'Acircumflexacute'       => 683,
        'Acircumflexdotbelow'       => 683,
        'Acircumflexgrave'       => 683,
        'Acircumflexhookabove'       => 683,
        'Acircumflextilde'       => 683,
        'Adieresis'       => 683,
        'Adotbelow'       => 683,
        'Agrave'       => 683,
        'Ahookabove'       => 683,
        'Alpha'       => 683,
        'Alphatonos'       => 683,
        'Amacron'       => 683,
        'Aogonek'       => 683,
        'Aring'       => 683,
        'Aringacute'       => 683,
        'Atilde'       => 683,
        'Aybarmenian'       => 748,
        'B'       => 685,
        'Benarmenian'       => 724,
        'Beta'       => 685,
        'C'       => 698,
        'Caarmenian'       => 783,
        'Cacute'       => 698,
        'Ccaron'       => 698,
        'Ccedilla'       => 698,
        'Ccircumflex'       => 698,
        'Cdotaccent'       => 698,
        'Chaarmenian'       => 666,
        'Cheabkhasiancyrillic'       => 878,
        'Chedescenderabkhasiancyrillic'       => 878,
        'Cheharmenian'       => 752,
        'Cheverticalstrokecyrillic'       => 711,
        'Chi'       => 685,
        'Coarmenian'       => 701,
        'D'       => 770,
        'Daarmenian'       => 704,
        'Dcaron'       => 770,
        'Dcroat'       => 775,
        'Delta'       => 703,
        'E'       => 632,
        'Eacute'       => 632,
        'Ebreve'       => 632,
        'Ecaron'       => 632,
        'Echarmenian'       => 735,
        'Ecircumflex'       => 632,
        'Ecircumflexacute'       => 632,
        'Ecircumflexdotbelow'       => 632,
        'Ecircumflexgrave'       => 632,
        'Ecircumflexhookabove'       => 632,
        'Ecircumflextilde'       => 632,
        'Edieresis'       => 632,
        'Edotaccent'       => 632,
        'Edotbelow'       => 632,
        'Egrave'       => 632,
        'Eharmenian'       => 627,
        'Ehookabove'       => 632,
        'Emacron'       => 632,
        'Endescendercyrillic'       => 751,
        'Eng'       => 748,
        'Eogonek'       => 632,
        'Epsilon'       => 632,
        'Epsilontonos'       => 750,
        'Eta'       => 751,
        'Etarmenian'       => 726,
        'Etatonos'       => 870,
        'Eth'       => 775,
        'Etilde'       => 632,
        'Euro'       => 635,
        'F'       => 574,
        'Feharmenian'       => 808,
        'G'       => 775,
        'Gamma'       => 566,
        'Gbreve'       => 775,
        'Gcircumflex'       => 775,
        'Gcommaaccent'       => 775,
        'Gdotaccent'       => 775,
        'Ghadarmenian'       => 713,
        'Ghestrokecyrillic'       => 566,
        'Gimarmenian'       => 718,
        'H'       => 751,
        'H18533'       => 604,
        'H18543'       => 354,
        'H18551'       => 354,
        'H22073'       => 604,
        'Haabkhasiancyrillic'       => 787,
        'Hadescendercyrillic'       => 685,
        'Hbar'       => 751,
        'Hcircumflex'       => 751,
        'Hoarmenian'       => 583,
        'I'       => 420,
        'IJ'       => 870,
        'Iacute'       => 420,
        'Ibreve'       => 420,
        'Icircumflex'       => 420,
        'Idieresis'       => 420,
        'Idotaccent'       => 420,
        'Idotbelow'       => 420,
        'Igrave'       => 420,
        'Ihookabove'       => 420,
        'Imacron'       => 420,
        'Iniarmenian'       => 677,
        'Iogonek'       => 420,
        'Iota'       => 420,
        'Iotadieresis'       => 420,
        'Iotatonos'       => 539,
        'Itilde'       => 420,
        'J'       => 454,
        'Jaarmenian'       => 700,
        'Jcircumflex'       => 454,
        'Jheharmenian'       => 738,
        'K'       => 692,
        'Kadescendercyrillic'       => 692,
        'Kappa'       => 692,
        'Kaverticalstrokecyrillic'       => 692,
        'Kcommaaccent'       => 692,
        'Keharmenian'       => 732,
        'Kenarmenian'       => 687,
        'L'       => 556,
        'Lacute'       => 556,
        'Lambda'       => 685,
        'Lcaron'       => 556,
        'Lcommaaccent'       => 556,
        'Ldot'       => 556,
        'Liwnarmenian'       => 547,
        'Lslash'       => 561,
        'M'       => 842,
        'Menarmenian'       => 760,
        'Mu'       => 842,
        'N'       => 748,
        'Nacute'       => 748,
        'Ncaron'       => 748,
        'Ncommaaccent'       => 748,
        'Nowarmenian'       => 694,
        'Ntilde'       => 748,
        'Nu'       => 748,
        'O'       => 787,
        'OE'       => 1069,
        'Oacute'       => 787,
        'Obarredcyrillic'       => 787,
        'Obreve'       => 787,
        'Ocircumflex'       => 787,
        'Ocircumflexacute'       => 787,
        'Ocircumflexdotbelow'       => 787,
        'Ocircumflexgrave'       => 787,
        'Ocircumflexhookabove'       => 787,
        'Ocircumflextilde'       => 787,
        'Odieresis'       => 787,
        'Odotbelow'       => 787,
        'Ograve'       => 787,
        'Oharmenian'       => 787,
        'Ohookabove'       => 787,
        'Ohorn'       => 806,
        'Ohornacute'       => 806,
        'Ohorndotbelow'       => 806,
        'Ohorngrave'       => 806,
        'Ohornhookabove'       => 806,
        'Ohorntilde'       => 806,
        'Ohungarumlaut'       => 787,
        'Omacron'       => 787,
        'Omega'       => 818,
        'Omegatitlocyrillic'       => 983,
        'Omegatonos'       => 907,
        'Omicron'       => 787,
        'Omicrontonos'       => 880,
        'Oslash'       => 787,
        'Oslashacute'       => 787,
        'Otilde'       => 787,
        'P'       => 603,
        'Peharmenian'       => 784,
        'Phi'       => 818,
        'Pi'       => 751,
        'Piwrarmenian'       => 818,
        'Psi'       => 870,
        'Q'       => 787,
        'R'       => 695,
        'Raarmenian'       => 761,
        'Racute'       => 695,
        'Rcaron'       => 695,
        'Rcommaaccent'       => 695,
        'Reharmenian'       => 680,
        'Rho'       => 603,
        'S'       => 683,
        'SF010000'       => 708,
        'SF020000'       => 708,
        'SF030000'       => 708,
        'SF040000'       => 708,
        'SF100000'       => 708,
        'SF110000'       => 708,
        'Sacute'       => 683,
        'Scaron'       => 683,
        'Scedilla'       => 683,
        'Schwa'       => 754,
        'Schwacyrillic'       => 754,
        'Scircumflex'       => 683,
        'Scommaaccent'       => 683,
        'Seharmenian'       => 731,
        'Shaarmenian'       => 687,
        'Shhacyrillic'       => 711,
        'Sigma'       => 672,
        'T'       => 616,
        'Tau'       => 616,
        'Tbar'       => 616,
        'Tcaron'       => 616,
        'Tcedilla'       => 616,
        'Tcommaaccent'       => 616,
        'Tedescendercyrillic'       => 616,
        'Tetsecyrillic'       => 909,
        'Theta'       => 787,
        'Thorn'       => 605,
        'Tiwnarmenian'       => 683,
        'Toarmenian'       => 802,
        'U'       => 731,
        'Uacute'       => 731,
        'Ubreve'       => 731,
        'Ucircumflex'       => 731,
        'Udieresis'       => 731,
        'Udotbelow'       => 731,
        'Ugrave'       => 731,
        'Uhookabove'       => 731,
        'Uhorn'       => 756,
        'Uhornacute'       => 756,
        'Uhorndotbelow'       => 756,
        'Uhorngrave'       => 756,
        'Uhornhookabove'       => 756,
        'Uhorntilde'       => 756,
        'Uhungarumlaut'       => 731,
        'Ukcyrillic'       => 1187,
        'Umacron'       => 731,
        'Uogonek'       => 731,
        'Upsilon'       => 615,
        'Upsilondieresis'       => 615,
        'Upsilontonos'       => 753,
        'Uring'       => 731,
        'Ustraightcyrillic'       => 615,
        'Ustraightstrokecyrillic'       => 615,
        'Utilde'       => 731,
        'V'       => 683,
        'Vewarmenian'       => 708,
        'Voarmenian'       => 733,
        'W'       => 988,
        'Wacute'       => 988,
        'Wcircumflex'       => 988,
        'Wdieresis'       => 988,
        'Wgrave'       => 988,
        'X'       => 685,
        'Xeharmenian'       => 842,
        'Xi'       => 648,
        'Y'       => 615,
        'Yacute'       => 615,
        'Ycircumflex'       => 615,
        'Ydieresis'       => 615,
        'Ydotbelow'       => 615,
        'Ygrave'       => 615,
        'Yhookabove'       => 615,
        'Yiarmenian'       => 674,
        'Yiwnarmenian'       => 518,
        'Ytilde'       => 615,
        'Z'       => 685,
        'Zaarmenian'       => 719,
        'Zacute'       => 685,
        'Zcaron'       => 685,
        'Zdotaccent'       => 685,
        'Zeta'       => 685,
        'Zhearmenian'       => 723,
        'Zhedescendercyrillic'       => 973,
        'a'       => 600,
        'aacute'       => 600,
        'abbreviationmarkarmenian'       => 518,
        'abreve'       => 600,
        'abreveacute'       => 600,
        'abrevedotbelow'       => 600,
        'abrevegrave'       => 600,
        'abrevehookabove'       => 600,
        'abrevetilde'       => 600,
        'acircumflex'       => 600,
        'acircumflexacute'       => 600,
        'acircumflexdotbelow'       => 600,
        'acircumflexgrave'       => 600,
        'acircumflexhookabove'       => 600,
        'acircumflextilde'       => 600,
        'acute'       => 635,
        'acutecomb'       => 0,
        'adieresis'       => 600,
        'adotbelow'       => 600,
        'ae'       => 955,
        'aeacute'       => 955,
        'afii00208'       => 1000,
        'afii10017'       => 683,
        'afii10018'       => 685,
        'afii10019'       => 685,
        'afii10020'       => 566,
        'afii10021'       => 745,
        'afii10022'       => 632,
        'afii10023'       => 632,
        'afii10024'       => 973,
        'afii10025'       => 615,
        'afii10026'       => 750,
        'afii10027'       => 750,
        'afii10028'       => 692,
        'afii10029'       => 734,
        'afii10030'       => 842,
        'afii10031'       => 751,
        'afii10032'       => 787,
        'afii10033'       => 751,
        'afii10034'       => 603,
        'afii10035'       => 698,
        'afii10036'       => 616,
        'afii10037'       => 615,
        'afii10038'       => 818,
        'afii10039'       => 685,
        'afii10040'       => 761,
        'afii10041'       => 711,
        'afii10042'       => 1030,
        'afii10043'       => 1044,
        'afii10044'       => 783,
        'afii10045'       => 920,
        'afii10046'       => 680,
        'afii10047'       => 701,
        'afii10048'       => 1034,
        'afii10049'       => 706,
        'afii10050'       => 566,
        'afii10051'       => 792,
        'afii10052'       => 566,
        'afii10053'       => 700,
        'afii10054'       => 683,
        'afii10055'       => 420,
        'afii10056'       => 420,
        'afii10057'       => 454,
        'afii10058'       => 1118,
        'afii10059'       => 1103,
        'afii10060'       => 817,
        'afii10061'       => 692,
        'afii10062'       => 615,
        'afii10065'       => 600,
        'afii10066'       => 614,
        'afii10067'       => 594,
        'afii10068'       => 471,
        'afii10069'       => 621,
        'afii10070'       => 595,
        'afii10071'       => 595,
        'afii10072'       => 797,
        'afii10073'       => 524,
        'afii10074'       => 640,
        'afii10075'       => 640,
        'afii10076'       => 591,
        'afii10077'       => 620,
        'afii10078'       => 696,
        'afii10079'       => 637,
        'afii10080'       => 606,
        'afii10081'       => 637,
        'afii10082'       => 623,
        'afii10083'       => 534,
        'afii10084'       => 496,
        'afii10085'       => 591,
        'afii10086'       => 840,
        'afii10087'       => 591,
        'afii10088'       => 644,
        'afii10089'       => 605,
        'afii10090'       => 875,
        'afii10091'       => 887,
        'afii10092'       => 640,
        'afii10093'       => 794,
        'afii10094'       => 570,
        'afii10095'       => 546,
        'afii10096'       => 838,
        'afii10097'       => 599,
        'afii10098'       => 471,
        'afii10099'       => 632,
        'afii10100'       => 471,
        'afii10101'       => 546,
        'afii10102'       => 520,
        'afii10103'       => 274,
        'afii10104'       => 274,
        'afii10105'       => 344,
        'afii10106'       => 914,
        'afii10107'       => 914,
        'afii10108'       => 632,
        'afii10109'       => 591,
        'afii10110'       => 591,
        'afii10145'       => 751,
        'afii10193'       => 637,
        'afii10846'       => 595,
        'afii57636'       => 834,
        'afii61248'       => 1076,
        'afii61289'       => 323,
        'afii61352'       => 1171,
        'agrave'       => 600,
        'ahookabove'       => 600,
        'alpha'       => 623,
        'alphatonos'       => 623,
        'amacron'       => 600,
        'ampersand'       => 726,
        'anoteleia'       => 454,
        'aogonek'       => 600,
        'apostrophearmenian'       => 224,
        'approxequal'       => 818,
        'aring'       => 600,
        'aringacute'       => 600,
        'asciicircum'       => 818,
        'asciitilde'       => 818,
        'asterisk'       => 635,
        'at'       => 1000,
        'atilde'       => 600,
        'aybarmenian'       => 974,
        'b'       => 623,
        'backslash'       => 454,
        'bahtthai'       => 685,
        'bar'       => 454,
        'benarmenian'       => 637,
        'beta'       => 620,
        'braceleft'       => 634,
        'braceright'       => 634,
        'bracketleft'       => 454,
        'bracketright'       => 454,
        'breve'       => 635,
        'brevecmb'       => 635,
        'brokenbar'       => 454,
        'bullet'       => 545,
        'c'       => 520,
        'caarmenian'       => 618,
        'cacute'       => 520,
        'caron'       => 635,
        'caroncmb'       => 635,
        'ccaron'       => 520,
        'ccedilla'       => 520,
        'ccircumflex'       => 520,
        'cdotaccent'       => 520,
        'cedilla'       => 635,
        'cent'       => 635,
        'chaarmenian'       => 433,
        'cheabkhasiancyrillic'       => 688,
        'chedescenderabkhasiancyrillic'       => 688,
        'cheharmenian'       => 602,
        'cheverticalstrokecyrillic'       => 605,
        'chi'       => 589,
        'circumflex'       => 635,
        'circumflexcmb'       => 635,
        'coarmenian'       => 623,
        'colon'       => 454,
        'colonmonetary'       => 698,
        'comma'       => 363,
        'commaarmenian'       => 187,
        'copyright'       => 1000,
        'cruzeiro'       => 698,
        'currency'       => 635,
        'd'       => 623,
        'daarmenian'       => 656,
        'dagger'       => 635,
        'daggerdbl'       => 635,
        'dbllowlinecmb'       => 0,
        'dcaron'       => 647,
        'dcroat'       => 623,
        'degree'       => 541,
        'delta'       => 607,
        'dieresis'       => 635,
        'dieresiscmb'       => 635,
        'dieresistonos'       => 635,
        'divide'       => 818,
        'dollar'       => 635,
        'dong'       => 623,
        'dotaccent'       => 635,
        'dotbelowcomb'       => 0,
        'dotlessi'       => 274,
        'dotlessj'       => 344,
        'e'       => 595,
        'eacute'       => 595,
        'ebreve'       => 595,
        'ecaron'       => 595,
        'echarmenian'       => 639,
        'echyiwnarmenian'       => 825,
        'ecircumflex'       => 595,
        'ecircumflexacute'       => 595,
        'ecircumflexdotbelow'       => 595,
        'ecircumflexgrave'       => 595,
        'ecircumflexhookabove'       => 595,
        'ecircumflextilde'       => 595,
        'edieresis'       => 595,
        'edotaccent'       => 595,
        'edotbelow'       => 595,
        'egrave'       => 595,
        'eharmenian'       => 547,
        'ehookabove'       => 595,
        'eight'       => 635,
        'eightinferior'       => 541,
        'eightsuperior'       => 541,
        'ellipsis'       => 818,
        'emacron'       => 595,
        'emdash'       => 1000,
        'emphasismarkarmenian'       => 163,
        'endash'       => 635,
        'endescendercyrillic'       => 637,
        'eng'       => 632,
        'eogonek'       => 595,
        'epsilon'       => 512,
        'epsilontonos'       => 512,
        'equal'       => 818,
        'equivalence'       => 818,
        'estimated'       => 717,
        'eta'       => 632,
        'etarmenian'       => 636,
        'etatonos'       => 632,
        'eth'       => 611,
        'etilde'       => 595,
        'exclam'       => 393,
        'exclamarmenian'       => 246,
        'exclamdbl'       => 624,
        'exclamdown'       => 393,
        'f'       => 351,
        'feharmenian'       => 743,
        'ff'       => 703,
        'ffi'       => 968,
        'ffl'       => 971,
        'fi'       => 625,
        'figuredash'       => 635,
        'five'       => 635,
        'fiveeighths'       => 1000,
        'fiveinferior'       => 541,
        'fivesuperior'       => 541,
        'fl'       => 625,
        'florin'       => 635,
        'four'       => 635,
        'fourinferior'       => 541,
        'foursuperior'       => 541,
        'fraction'       => 361,
        'franc'       => 635,
        'g'       => 623,
        'gamma'       => 591,
        'gbreve'       => 623,
        'gcircumflex'       => 623,
        'gcommaaccent'       => 623,
        'gdotaccent'       => 623,
        'germandbls'       => 620,
        'ghadarmenian'       => 642,
        'ghestrokecyrillic'       => 471,
        'gimarmenian'       => 640,
        'grave'       => 635,
        'gravecomb'       => 0,
        'greater'       => 818,
        'greaterequal'       => 818,
        'guillemotleft'       => 644,
        'guillemotright'       => 644,
        'guilsinglleft'       => 454,
        'guilsinglright'       => 454,
        'h'       => 632,
        'haabkhasiancyrillic'       => 616,
        'hadescendercyrillic'       => 591,
        'hbar'       => 632,
        'hcircumflex'       => 632,
        'hoarmenian'       => 632,
        'hookabovecomb'       => 0,
        'hungarumlaut'       => 635,
        'hungarumlautcmb'       => 635,
        'hyphen'       => 454,
        'i'       => 274,
        'iacute'       => 274,
        'ibreve'       => 274,
        'icircumflex'       => 274,
        'idieresis'       => 274,
        'idotbelow'       => 274,
        'igrave'       => 274,
        'ihookabove'       => 274,
        'ij'       => 613,
        'imacron'       => 274,
        'infinity'       => 1000,
        'iniarmenian'       => 636,
        'integral'       => 635,
        'iogonek'       => 274,
        'iota'       => 274,
        'iotadieresis'       => 274,
        'iotadieresistonos'       => 274,
        'iotatonos'       => 274,
        'itilde'       => 274,
        'j'       => 344,
        'jaarmenian'       => 606,
        'jcircumflex'       => 344,
        'jheharmenian'       => 542,
        'k'       => 591,
        'kadescendercyrillic'       => 591,
        'kappa'       => 591,
        'kaverticalstrokecyrillic'       => 591,
        'kcommaaccent'       => 591,
        'keharmenian'       => 645,
        'kenarmenian'       => 636,
        'kgreenlandic'       => 591,
        'l'       => 274,
        'lacute'       => 274,
        'lambda'       => 591,
        'lcaron'       => 295,
        'lcommaaccent'       => 274,
        'ldot'       => 458,
        'less'       => 818,
        'lessequal'       => 818,
        'lira'       => 635,
        'liwnarmenian'       => 277,
        'logicalnot'       => 818,
        'longs'       => 300,
        'lozenge'       => 818,
        'lslash'       => 284,
        'm'       => 972,
        'macron'       => 635,
        'menarmenian'       => 636,
        'minus'       => 818,
        'minute'       => 361,
        'mu'       => 639,
        'multiply'       => 818,
        'musicalnote'       => 500,
        'n'       => 632,
        'nacute'       => 632,
        'napostrophe'       => 730,
        'ncaron'       => 632,
        'ncommaaccent'       => 632,
        'nine'       => 635,
        'nineinferior'       => 541,
        'ninesuperior'       => 541,
        'notequal'       => 818,
        'nowarmenian'       => 639,
        'nsuperior'       => 545,
        'ntilde'       => 632,
        'nu'       => 591,
        'numbersign'       => 818,
        'o'       => 606,
        'oacute'       => 606,
        'obarredcyrillic'       => 606,
        'obreve'       => 606,
        'ocircumflex'       => 606,
        'ocircumflexacute'       => 606,
        'ocircumflexdotbelow'       => 606,
        'ocircumflexgrave'       => 606,
        'ocircumflexhookabove'       => 606,
        'ocircumflextilde'       => 606,
        'odieresis'       => 606,
        'odotbelow'       => 606,
        'oe'       => 981,
        'ogonek'       => 635,
        'ograve'       => 606,
        'oharmenian'       => 606,
        'ohookabove'       => 606,
        'ohorn'       => 606,
        'ohornacute'       => 606,
        'ohorndotbelow'       => 606,
        'ohorngrave'       => 606,
        'ohornhookabove'       => 606,
        'ohorntilde'       => 606,
        'ohungarumlaut'       => 606,
        'omacron'       => 606,
        'omega'       => 813,
        'omega1'       => 707,
        'omegatitlocyrillic'       => 813,
        'omegatonos'       => 813,
        'omicron'       => 606,
        'omicrontonos'       => 606,
        'one'       => 635,
        'oneeighth'       => 1000,
        'onehalf'       => 1000,
        'oneinferior'       => 541,
        'onequarter'       => 1000,
        'onesuperior'       => 541,
        'openbullet'       => 354,
        'ordfeminine'       => 545,
        'ordmasculine'       => 545,
        'oslash'       => 606,
        'oslashacute'       => 606,
        'otilde'       => 606,
        'overline'       => 635,
        'p'       => 623,
        'paragraph'       => 635,
        'parenleft'       => 454,
        'parenright'       => 454,
        'partialdiff'       => 635,
        'peharmenian'       => 976,
        'percent'       => 1076,
        'period'       => 363,
        'periodarmenian'       => 174,
        'periodcentered'       => 363,
        'perthousand'       => 1521,
        'peseta'       => 1163,
        'phi'       => 790,
        'pi'       => 637,
        'piwrarmenian'       => 971,
        'plus'       => 818,
        'plusminus'       => 818,
        'product'       => 818,
        'psi'       => 821,
        'q'       => 623,
        'question'       => 545,
        'questionarmenian'       => 281,
        'questiondown'       => 545,
        'questiongreek'       => 454,
        'quotedbl'       => 458,
        'quotedblbase'       => 458,
        'quotedblleft'       => 458,
        'quotedblright'       => 458,
        'quoteleft'       => 268,
        'quotereversed'       => 268,
        'quoteright'       => 268,
        'quotesinglbase'       => 268,
        'quotesingle'       => 268,
        'r'       => 426,
        'raarmenian'       => 659,
        'racute'       => 426,
        'radical'       => 818,
        'rcaron'       => 426,
        'rcommaaccent'       => 426,
        'registered'       => 1000,
        'reharmenian'       => 636,
        'rho'       => 625,
        'ring'       => 635,
        'ringhalfleftarmenian'       => 236,
        's'       => 520,
        'sacute'       => 520,
        'scaron'       => 520,
        'scedilla'       => 520,
        'schwa'       => 595,
        'scircumflex'       => 520,
        'scommaaccent'       => 520,
        'second'       => 557,
        'section'       => 635,
        'seharmenian'       => 632,
        'seven'       => 635,
        'seveneighths'       => 1000,
        'seveninferior'       => 541,
        'sevensuperior'       => 541,
        'shaarmenian'       => 479,
        'shhacyrillic'       => 632,
        'sigma'       => 630,
        'sigma1'       => 507,
        'six'       => 635,
        'sixinferior'       => 541,
        'sixsuperior'       => 541,
        'slash'       => 454,
        'space'       => 351,
        'sterling'       => 635,
        'summation'       => 727,
        't'       => 394,
        'tau'       => 496,
        'tbar'       => 394,
        'tcaron'       => 394,
        'tcedilla'       => 394,
        'tcommaaccent'       => 394,
        'tedescendercyrillic'       => 496,
        'tetsecyrillic'       => 745,
        'theta'       => 624,
        'thorn'       => 623,
        'three'       => 635,
        'threeeighths'       => 1000,
        'threeinferior'       => 541,
        'threequarters'       => 1000,
        'threesuperior'       => 541,
        'tilde'       => 635,
        'tildecomb'       => 0,
        'tiwnarmenian'       => 971,
        'toarmenian'       => 786,
        'tonos'       => 635,
        'tprime'       => 557,
        'trademark'       => 976,
        'two'       => 635,
        'twoinferior'       => 541,
        'twosuperior'       => 541,
        'u'       => 632,
        'uacute'       => 632,
        'ubreve'       => 632,
        'ucircumflex'       => 632,
        'udieresis'       => 632,
        'udotbelow'       => 632,
        'ugrave'       => 632,
        'uhookabove'       => 632,
        'uhorn'       => 659,
        'uhornacute'       => 659,
        'uhorndotbelow'       => 659,
        'uhorngrave'       => 659,
        'uhornhookabove'       => 659,
        'uhorntilde'       => 659,
        'uhungarumlaut'       => 632,
        'ukcyrillic'       => 1040,
        'umacron'       => 632,
        'underscore'       => 635,
        'underscoredbl'       => 635,
        'uni0326'       => 363,
        'uni0347'       => 0,
        'uni040D'       => 750,
        'uni045D'       => 640,
        'uni0487'       => 635,
        'uni04F6'       => 566,
        'uni04F7'       => 471,
        'uni051A'       => 787,
        'uni051B'       => 623,
        'uni051C'       => 988,
        'uni051D'       => 818,
        'uni058A'       => 363,
        'uni058F'       => 635,
        'uni1E9E'       => 677,
        'uni201F'       => 458,
        'uni202F'       => 175,
        'uni20A0'       => 635,
        'uni20A5'       => 972,
        'uni20A6'       => 748,
        'uni20A8'       => 1166,
        'uni20AD'       => 692,
        'uni20AE'       => 616,
        'uni20AF'       => 1000,
        'uni20B0'       => 520,
        'uni20B1'       => 603,
        'uni20B2'       => 775,
        'uni20B3'       => 683,
        'uni20B4'       => 683,
        'uni20B5'       => 698,
        'uni20B8'       => 635,
        'uni20B9'       => 635,
        'uni20BA'       => 635,
        'uni20BB'       => 635,
        'uni20BC'       => 809,
        'uni20BD'       => 635,
        'uni20BE'       => 712,
        'uni20F0'       => 0,
        'uni2120'       => 1128,
        'uni2C6D'       => 768,
        'uni2C71'       => 646,
        'uni2C72'       => 1056,
        'uni2C73'       => 875,
        'uniA71B'       => 446,
        'uniA71C'       => 446,
        'uniA71D'       => 266,
        'uniA71E'       => 266,
        'uniA71F'       => 266,
        'uniA788'       => 635,
        'uniA789'       => 454,
        'uniA78A'       => 532,
        'uniA78B'       => 268,
        'uniA78C'       => 268,
        'uniFB13'       => 1275,
        'uniFB14'       => 1275,
        'uniFB15'       => 1275,
        'uniFB16'       => 1275,
        'uniFB17'       => 1615,
        'uniFFFD'       => 927,
        'uogonek'       => 630,
        'upsilon'       => 631,
        'upsilondieresis'       => 631,
        'upsilondieresistonos'       => 631,
        'upsilontonos'       => 631,
        'uring'       => 632,
        'ustraightcyrillic'       => 591,
        'ustraightstrokecyrillic'       => 591,
        'utilde'       => 632,
        'v'       => 591,
        'vewarmenian'       => 641,
        'voarmenian'       => 632,
        'w'       => 818,
        'wacute'       => 818,
        'wcircumflex'       => 818,
        'wdieresis'       => 818,
        'wgrave'       => 818,
        'wonmonospace'       => 988,
        'x'       => 591,
        'xeharmenian'       => 981,
        'xi'       => 502,
        'y'       => 591,
        'yacute'       => 591,
        'ycircumflex'       => 591,
        'ydieresis'       => 591,
        'ydotbelow'       => 591,
        'yenmonospace'       => 635,
        'ygrave'       => 591,
        'yhookabove'       => 591,
        'yiarmenian'       => 277,
        'yiwnarmenian'       => 463,
        'ytilde'       => 591,
        'z'       => 525,
        'zaarmenian'       => 625,
        'zacute'       => 525,
        'zcaron'       => 525,
        'zdotaccent'       => 525,
        'zero'       => 635,
        'zeroinferior'       => 541,
        'zerosuperior'       => 541,
        'zeta'       => 457,
        'zhearmenian'       => 638,
        'zhedescendercyrillic'       => 797,
    },
    'wxold' => { # HORIZ. WIDTH TABLE
        'space' => '351',                        # C+0x20 # U+0x0020
        'exclam' => '393',                       # C+0x21 # U+0x0021
        'quotedbl' => '458',                     # C+0x22 # U+0x0022
        'numbersign' => '818',                   # C+0x23 # U+0x0023
        'dollar' => '635',                       # C+0x24 # U+0x0024
        'percent' => '1076',                     # C+0x25 # U+0x0025
        'ampersand' => '726',                    # C+0x26 # U+0x0026
        'quotesingle' => '268',                  # C+0x27 # U+0x0027
        'parenleft' => '454',                    # C+0x28 # U+0x0028
        'parenright' => '454',                   # C+0x29 # U+0x0029
        'asterisk' => '635',                     # C+0x2A # U+0x002A
        'plus' => '818',                         # C+0x2B # U+0x002B
        'comma' => '363',                        # C+0x2C # U+0x002C
        'hyphen' => '454',                       # C+0x2D # U+0x002D
        'period' => '363',                       # C+0x2E # U+0x002E
        'slash' => '454',                        # C+0x2F # U+0x002F
        'zero' => '635',                         # C+0x30 # U+0x0030
        'one' => '635',                          # C+0x31 # U+0x0031
        'two' => '635',                          # C+0x32 # U+0x0032
        'three' => '635',                        # C+0x33 # U+0x0033
        'four' => '635',                         # C+0x34 # U+0x0034
        'five' => '635',                         # C+0x35 # U+0x0035
        'six' => '635',                          # C+0x36 # U+0x0036
        'seven' => '635',                        # C+0x37 # U+0x0037
        'eight' => '635',                        # C+0x38 # U+0x0038
        'nine' => '635',                         # C+0x39 # U+0x0039
        'colon' => '454',                        # C+0x3A # U+0x003A
        'semicolon' => '454',                    # C+0x3B # U+0x003B
        'less' => '818',                         # C+0x3C # U+0x003C
        'equal' => '818',                        # C+0x3D # U+0x003D
        'greater' => '818',                      # C+0x3E # U+0x003E
        'question' => '545',                     # C+0x3F # U+0x003F
        'at' => '1000',                          # C+0x40 # U+0x0040
        'A' => '683',                            # C+0x41 # U+0x0041
        'B' => '685',                            # C+0x42 # U+0x0042
        'C' => '698',                            # C+0x43 # U+0x0043
        'D' => '770',                            # C+0x44 # U+0x0044
        'E' => '632',                            # C+0x45 # U+0x0045
        'F' => '574',                            # C+0x46 # U+0x0046
        'G' => '775',                            # C+0x47 # U+0x0047
        'H' => '751',                            # C+0x48 # U+0x0048
        'I' => '420',                            # C+0x49 # U+0x0049
        'J' => '454',                            # C+0x4A # U+0x004A
        'K' => '692',                            # C+0x4B # U+0x004B
        'L' => '556',                            # C+0x4C # U+0x004C
        'M' => '842',                            # C+0x4D # U+0x004D
        'N' => '748',                            # C+0x4E # U+0x004E
        'O' => '787',                            # C+0x4F # U+0x004F
        'P' => '603',                            # C+0x50 # U+0x0050
        'Q' => '787',                            # C+0x51 # U+0x0051
        'R' => '695',                            # C+0x52 # U+0x0052
        'S' => '683',                            # C+0x53 # U+0x0053
        'T' => '616',                            # C+0x54 # U+0x0054
        'U' => '731',                            # C+0x55 # U+0x0055
        'V' => '683',                            # C+0x56 # U+0x0056
        'W' => '988',                            # C+0x57 # U+0x0057
        'X' => '685',                            # C+0x58 # U+0x0058
        'Y' => '615',                            # C+0x59 # U+0x0059
        'Z' => '685',                            # C+0x5A # U+0x005A
        'bracketleft' => '454',                  # C+0x5B # U+0x005B
        'backslash' => '454',                    # C+0x5C # U+0x005C
        'bracketright' => '454',                 # C+0x5D # U+0x005D
        'asciicircum' => '818',                  # C+0x5E # U+0x005E
        'underscore' => '635',                   # C+0x5F # U+0x005F
        'grave' => '635',                        # C+0x60 # U+0x0060
        'a' => '600',                            # C+0x61 # U+0x0061
        'b' => '623',                            # C+0x62 # U+0x0062
        'c' => '520',                            # C+0x63 # U+0x0063
        'd' => '623',                            # C+0x64 # U+0x0064
        'e' => '595',                            # C+0x65 # U+0x0065
        'f' => '351',                            # C+0x66 # U+0x0066
        'g' => '623',                            # C+0x67 # U+0x0067
        'h' => '632',                            # C+0x68 # U+0x0068
        'i' => '274',                            # C+0x69 # U+0x0069
        'j' => '344',                            # C+0x6A # U+0x006A
        'k' => '591',                            # C+0x6B # U+0x006B
        'l' => '274',                            # C+0x6C # U+0x006C
        'm' => '972',                            # C+0x6D # U+0x006D
        'n' => '632',                            # C+0x6E # U+0x006E
        'o' => '606',                            # C+0x6F # U+0x006F
        'p' => '623',                            # C+0x70 # U+0x0070
        'q' => '623',                            # C+0x71 # U+0x0071
        'r' => '426',                            # C+0x72 # U+0x0072
        's' => '520',                            # C+0x73 # U+0x0073
        't' => '394',                            # C+0x74 # U+0x0074
        'u' => '632',                            # C+0x75 # U+0x0075
        'v' => '591',                            # C+0x76 # U+0x0076
        'w' => '818',                            # C+0x77 # U+0x0077
        'x' => '591',                            # C+0x78 # U+0x0078
        'y' => '591',                            # C+0x79 # U+0x0079
        'z' => '525',                            # C+0x7A # U+0x007A
        'braceleft' => '634',                    # C+0x7B # U+0x007B
        'bar' => '454',                          # C+0x7C # U+0x007C
        'braceright' => '634',                   # C+0x7D # U+0x007D
        'asciitilde' => '818',                   # C+0x7E # U+0x007E
        'bullet' => '545',                       # C+0x7F # U+0x2022
        'Euro' => '635',                         # C+0x80 # U+0x20AC
        'quotesinglbase' => '268',               # C+0x82 # U+0x201A
        'florin' => '635',                       # C+0x83 # U+0x0192
        'quotedblbase' => '458',                 # C+0x84 # U+0x201E
        'ellipsis' => '818',                     # C+0x85 # U+0x2026
        'dagger' => '635',                       # C+0x86 # U+0x2020
        'daggerdbl' => '635',                    # C+0x87 # U+0x2021
        'circumflex' => '635',                   # C+0x88 # U+0x02C6
        'perthousand' => '1521',                 # C+0x89 # U+0x2030
        'Scaron' => '683',                       # C+0x8A # U+0x0160
        'guilsinglleft' => '454',                # C+0x8B # U+0x2039
        'OE' => '1069',                          # C+0x8C # U+0x0152
        'Zcaron' => '685',                       # C+0x8E # U+0x017D
        'quoteleft' => '268',                    # C+0x91 # U+0x2018
        'quoteright' => '268',                   # C+0x92 # U+0x2019
        'quotedblleft' => '458',                 # C+0x93 # U+0x201C
        'quotedblright' => '458',                # C+0x94 # U+0x201D
        'endash' => '635',                       # C+0x96 # U+0x2013
        'emdash' => '1000',                      # C+0x97 # U+0x2014
        'tilde' => '635',                        # C+0x98 # U+0x02DC
        'trademark' => '976',                    # C+0x99 # U+0x2122
        'scaron' => '520',                       # C+0x9A # U+0x0161
        'guilsinglright' => '454',               # C+0x9B # U+0x203A
        'oe' => '981',                           # C+0x9C # U+0x0153
        'zcaron' => '525',                       # C+0x9E # U+0x017E
        'Ydieresis' => '615',                    # C+0x9F # U+0x0178
        'exclamdown' => '393',                   # C+0xA1 # U+0x00A1
        'cent' => '635',                         # C+0xA2 # U+0x00A2
        'sterling' => '635',                     # C+0xA3 # U+0x00A3
        'currency' => '635',                     # C+0xA4 # U+0x00A4
        'yen' => '635',                          # C+0xA5 # U+0x00A5
        'brokenbar' => '454',                    # C+0xA6 # U+0x00A6
        'section' => '635',                      # C+0xA7 # U+0x00A7
        'dieresis' => '635',                     # C+0xA8 # U+0x00A8
        'copyright' => '1000',                   # C+0xA9 # U+0x00A9
        'ordfeminine' => '545',                  # C+0xAA # U+0x00AA
        'guillemotleft' => '644',                # C+0xAB # U+0x00AB
        'logicalnot' => '818',                   # C+0xAC # U+0x00AC
        'registered' => '1000',                  # C+0xAE # U+0x00AE
        'macron' => '635',                       # C+0xAF # U+0x00AF
        'degree' => '541',                       # C+0xB0 # U+0x00B0
        'plusminus' => '818',                    # C+0xB1 # U+0x00B1
        'twosuperior' => '541',                  # C+0xB2 # U+0x00B2
        'threesuperior' => '541',                # C+0xB3 # U+0x00B3
        'acute' => '635',                        # C+0xB4 # U+0x00B4
        'mu' => '639',                           # C+0xB5 # U+0x00B5
        'paragraph' => '635',                    # C+0xB6 # U+0x00B6
        'periodcentered' => '363',               # C+0xB7 # U+0x00B7
        'cedilla' => '635',                      # C+0xB8 # U+0x00B8
        'onesuperior' => '541',                  # C+0xB9 # U+0x00B9
        'ordmasculine' => '545',                 # C+0xBA # U+0x00BA
        'guillemotright' => '644',               # C+0xBB # U+0x00BB
        'onequarter' => '1000',                  # C+0xBC # U+0x00BC
        'onehalf' => '1000',                     # C+0xBD # U+0x00BD
        'threequarters' => '1000',               # C+0xBE # U+0x00BE
        'questiondown' => '545',                 # C+0xBF # U+0x00BF
        'Agrave' => '683',                       # C+0xC0 # U+0x00C0
        'Aacute' => '683',                       # C+0xC1 # U+0x00C1
        'Acircumflex' => '683',                  # C+0xC2 # U+0x00C2
        'Atilde' => '683',                       # C+0xC3 # U+0x00C3
        'Adieresis' => '683',                    # C+0xC4 # U+0x00C4
        'Aring' => '683',                        # C+0xC5 # U+0x00C5
        'AE' => '984',                           # C+0xC6 # U+0x00C6
        'Ccedilla' => '698',                     # C+0xC7 # U+0x00C7
        'Egrave' => '632',                       # C+0xC8 # U+0x00C8
        'Eacute' => '632',                       # C+0xC9 # U+0x00C9
        'Ecircumflex' => '632',                  # C+0xCA # U+0x00CA
        'Edieresis' => '632',                    # C+0xCB # U+0x00CB
        'Igrave' => '420',                       # C+0xCC # U+0x00CC
        'Iacute' => '420',                       # C+0xCD # U+0x00CD
        'Icircumflex' => '420',                  # C+0xCE # U+0x00CE
        'Idieresis' => '420',                    # C+0xCF # U+0x00CF
        'Eth' => '775',                          # C+0xD0 # U+0x00D0
        'Ntilde' => '748',                       # C+0xD1 # U+0x00D1
        'Ograve' => '787',                       # C+0xD2 # U+0x00D2
        'Oacute' => '787',                       # C+0xD3 # U+0x00D3
        'Ocircumflex' => '787',                  # C+0xD4 # U+0x00D4
        'Otilde' => '787',                       # C+0xD5 # U+0x00D5
        'Odieresis' => '787',                    # C+0xD6 # U+0x00D6
        'multiply' => '818',                     # C+0xD7 # U+0x00D7
        'Oslash' => '787',                       # C+0xD8 # U+0x00D8
        'Ugrave' => '731',                       # C+0xD9 # U+0x00D9
        'Uacute' => '731',                       # C+0xDA # U+0x00DA
        'Ucircumflex' => '731',                  # C+0xDB # U+0x00DB
        'Udieresis' => '731',                    # C+0xDC # U+0x00DC
        'Yacute' => '615',                       # C+0xDD # U+0x00DD
        'Thorn' => '605',                        # C+0xDE # U+0x00DE
        'germandbls' => '620',                   # C+0xDF # U+0x00DF
        'agrave' => '600',                       # C+0xE0 # U+0x00E0
        'aacute' => '600',                       # C+0xE1 # U+0x00E1
        'acircumflex' => '600',                  # C+0xE2 # U+0x00E2
        'atilde' => '600',                       # C+0xE3 # U+0x00E3
        'adieresis' => '600',                    # C+0xE4 # U+0x00E4
        'aring' => '600',                        # C+0xE5 # U+0x00E5
        'ae' => '955',                           # C+0xE6 # U+0x00E6
        'ccedilla' => '520',                     # C+0xE7 # U+0x00E7
        'egrave' => '595',                       # C+0xE8 # U+0x00E8
        'eacute' => '595',                       # C+0xE9 # U+0x00E9
        'ecircumflex' => '595',                  # C+0xEA # U+0x00EA
        'edieresis' => '595',                    # C+0xEB # U+0x00EB
        'igrave' => '274',                       # C+0xEC # U+0x00EC
        'iacute' => '274',                       # C+0xED # U+0x00ED
        'icircumflex' => '274',                  # C+0xEE # U+0x00EE
        'idieresis' => '274',                    # C+0xEF # U+0x00EF
        'eth' => '611',                          # C+0xF0 # U+0x00F0
        'ntilde' => '632',                       # C+0xF1 # U+0x00F1
        'ograve' => '606',                       # C+0xF2 # U+0x00F2
        'oacute' => '606',                       # C+0xF3 # U+0x00F3
        'ocircumflex' => '606',                  # C+0xF4 # U+0x00F4
        'otilde' => '606',                       # C+0xF5 # U+0x00F5
        'odieresis' => '606',                    # C+0xF6 # U+0x00F6
        'divide' => '818',                       # C+0xF7 # U+0x00F7
        'oslash' => '606',                       # C+0xF8 # U+0x00F8
        'ugrave' => '632',                       # C+0xF9 # U+0x00F9
        'uacute' => '632',                       # C+0xFA # U+0x00FA
        'ucircumflex' => '632',                  # C+0xFB # U+0x00FB
        'udieresis' => '632',                    # C+0xFC # U+0x00FC
        'yacute' => '591',                       # C+0xFD # U+0x00FD
        'thorn' => '623',                        # C+0xFE # U+0x00FE
        'ydieresis' => '591',                    # C+0xFF # U+0x00FF
        'middot' => '363',                       # U+0x00B7
        'Amacron' => '683',                      # U+0x0100
        'amacron' => '600',                      # U+0x0101
        'Abreve' => '683',                       # U+0x0102
        'abreve' => '600',                       # U+0x0103
        'Aogonek' => '683',                      # U+0x0104
        'aogonek' => '600',                      # U+0x0105
        'Cacute' => '698',                       # U+0x0106
        'cacute' => '520',                       # U+0x0107
        'Ccircumflex' => '698',                  # U+0x0108
        'ccircumflex' => '520',                  # U+0x0109
        'Cdot' => '698',                         # U+0x010A
        'cdot' => '520',                         # U+0x010B
        'Ccaron' => '698',                       # U+0x010C
        'ccaron' => '520',                       # U+0x010D
        'Dcaron' => '770',                       # U+0x010E
        'dcaron' => '647',                       # U+0x010F
        'Emacron' => '632',                      # U+0x0112
        'emacron' => '595',                      # U+0x0113
        'Ebreve' => '632',                       # U+0x0114
        'ebreve' => '595',                       # U+0x0115
        'Edot' => '632',                         # U+0x0116
        'edot' => '595',                         # U+0x0117
        'Eogonek' => '632',                      # U+0x0118
        'eogonek' => '595',                      # U+0x0119
        'Ecaron' => '632',                       # U+0x011A
        'ecaron' => '595',                       # U+0x011B
        'Gcircumflex' => '775',                  # U+0x011C
        'gcircumflex' => '623',                  # U+0x011D
        'Gbreve' => '775',                       # U+0x011E
        'gbreve' => '623',                       # U+0x011F
        'Gdot' => '775',                         # U+0x0120
        'gdot' => '623',                         # U+0x0121
        'Hcircumflex' => '751',                  # U+0x0124
        'hcircumflex' => '632',                  # U+0x0125
        'Hbar' => '751',                         # U+0x0126
        'hbar' => '632',                         # U+0x0127
        'Itilde' => '420',                       # U+0x0128
        'itilde' => '274',                       # U+0x0129
        'Imacron' => '420',                      # U+0x012A
        'imacron' => '274',                      # U+0x012B
        'Ibreve' => '420',                       # U+0x012C
        'ibreve' => '274',                       # U+0x012D
        'Iogonek' => '420',                      # U+0x012E
        'iogonek' => '274',                      # U+0x012F
        'Idot' => '420',                         # U+0x0130
        'dotlessi' => '274',                     # U+0x0131
        'IJ' => '870',                           # U+0x0132
        'ij' => '613',                           # U+0x0133
        'Jcircumflex' => '454',                  # U+0x0134
        'jcircumflex' => '344',                  # U+0x0135
        'kgreenlandic' => '591',                 # U+0x0138
        'Lacute' => '556',                       # U+0x0139
        'lacute' => '274',                       # U+0x013A
        'Lcaron' => '556',                       # U+0x013D
        'lcaron' => '295',                       # U+0x013E
        'Ldot' => '556',                         # U+0x013F
        'ldot' => '458',                         # U+0x0140
        'Lslash' => '561',                       # U+0x0141
        'lslash' => '284',                       # U+0x0142
        'Nacute' => '748',                       # U+0x0143
        'nacute' => '632',                       # U+0x0144
        'Ncaron' => '748',                       # U+0x0147
        'ncaron' => '632',                       # U+0x0148
        'napostrophe' => '730',                  # U+0x0149
        'Eng' => '748',                          # U+0x014A
        'eng' => '632',                          # U+0x014B
        'Omacron' => '787',                      # U+0x014C
        'omacron' => '606',                      # U+0x014D
        'Obreve' => '787',                       # U+0x014E
        'obreve' => '606',                       # U+0x014F
        'Racute' => '695',                       # U+0x0154
        'racute' => '426',                       # U+0x0155
        'Rcaron' => '695',                       # U+0x0158
        'rcaron' => '426',                       # U+0x0159
        'Sacute' => '683',                       # U+0x015A
        'sacute' => '520',                       # U+0x015B
        'Scircumflex' => '683',                  # U+0x015C
        'scircumflex' => '520',                  # U+0x015D
        'Scedilla' => '683',                     # U+0x015E
        'scedilla' => '520',                     # U+0x015F
        'Tcaron' => '616',                       # U+0x0164
        'tcaron' => '394',                       # U+0x0165
        'Tbar' => '616',                         # U+0x0166
        'tbar' => '394',                         # U+0x0167
        'Utilde' => '731',                       # U+0x0168
        'utilde' => '632',                       # U+0x0169
        'Umacron' => '731',                      # U+0x016A
        'umacron' => '632',                      # U+0x016B
        'Ubreve' => '731',                       # U+0x016C
        'ubreve' => '630',                       # U+0x016D
        'Uring' => '731',                        # U+0x016E
        'uring' => '632',                        # U+0x016F
        'Uogonek' => '731',                      # U+0x0172
        'uogonek' => '630',                      # U+0x0173
        'Wcircumflex' => '988',                  # U+0x0174
        'wcircumflex' => '818',                  # U+0x0175
        'Ycircumflex' => '615',                  # U+0x0176
        'ycircumflex' => '591',                  # U+0x0177
        'Zacute' => '685',                       # U+0x0179
        'zacute' => '525',                       # U+0x017A
        'Zdot' => '685',                         # U+0x017B
        'zdot' => '525',                         # U+0x017C
        'longs' => '300',                        # U+0x017F
        'Ohorn' => '806',                        # U+0x01A0
        'ohorn' => '606',                        # U+0x01A1
        'Uhorn' => '756',                        # U+0x01AF
        'uhorn' => '659',                        # U+0x01B0
        'Aringacute' => '683',                   # U+0x01FA
        'aringacute' => '600',                   # U+0x01FB
        'AEacute' => '984',                      # U+0x01FC
        'aeacute' => '955',                      # U+0x01FD
        'Oslashacute' => '787',                  # U+0x01FE
        'oslashacute' => '606',                  # U+0x01FF
        'caron' => '635',                        # U+0x02C7
        'breve' => '635',                        # U+0x02D8
        'dotaccent' => '635',                    # U+0x02D9
        'ring' => '635',                         # U+0x02DA
        'ogonek' => '635',                       # U+0x02DB
        'hungarumlaut' => '635',                 # U+0x02DD
        'dblgravecmb' => '635',                  # U+0x030F
        'gravecomb' => '0',                      # U+0x0300
        'acutecomb' => '0',                      # U+0x0301
        'tildecomb' => '0',                      # U+0x0303
        'hookabovecomb' => '0',                  # U+0x0309
        'dotbelowcomb' => '0',                   # U+0x0323
        'tonos' => '635',                        # U+0x0384
        'dieresistonos' => '635',                # U+0x0385
        'Alphatonos' => '683',                   # U+0x0386
        'anoteleia' => '454',                    # U+0x0387
        'Epsilontonos' => '750',                 # U+0x0388
        'Etatonos' => '870',                     # U+0x0389
        'Iotatonos' => '539',                    # U+0x038A
        'Omicrontonos' => '880',                 # U+0x038C
        'Upsilontonos' => '753',                 # U+0x038E
        'Omegatonos' => '907',                   # U+0x038F
        'iotadieresistonos' => '274',            # U+0x0390
        'Alpha' => '683',                        # U+0x0391
        'Beta' => '685',                         # U+0x0392
        'Gamma' => '566',                        # U+0x0393
        'Delta' => '703',                        # U+0x0394
        'Epsilon' => '632',                      # U+0x0395
        'Zeta' => '685',                         # U+0x0396
        'Eta' => '751',                          # U+0x0397
        'Theta' => '787',                        # U+0x0398
        'Iota' => '420',                         # U+0x0399
        'Kappa' => '692',                        # U+0x039A
        'Lambda' => '685',                       # U+0x039B
        'Mu' => '842',                           # U+0x039C
        'Nu' => '748',                           # U+0x039D
        'Xi' => '648',                           # U+0x039E
        'Omicron' => '787',                      # U+0x039F
        'Pi' => '751',                           # U+0x03A0
        'Rho' => '603',                          # U+0x03A1
        'Sigma' => '672',                        # U+0x03A3
        'Tau' => '616',                          # U+0x03A4
        'Upsilon' => '615',                      # U+0x03A5
        'Phi' => '818',                          # U+0x03A6
        'Chi' => '685',                          # U+0x03A7
        'Psi' => '870',                          # U+0x03A8
        'Omega' => '818',                        # U+0x03A9
        'Iotadieresis' => '420',                 # U+0x03AA
        'Upsilondieresis' => '615',              # U+0x03AB
        'alphatonos' => '623',                   # U+0x03AC
        'epsilontonos' => '512',                 # U+0x03AD
        'etatonos' => '632',                     # U+0x03AE
        'iotatonos' => '274',                    # U+0x03AF
        'upsilondieresistonos' => '631',         # U+0x03B0
        'alpha' => '623',                        # U+0x03B1
        'beta' => '620',                         # U+0x03B2
        'gamma' => '591',                        # U+0x03B3
        'delta' => '607',                        # U+0x03B4
        'epsilon' => '512',                      # U+0x03B5
        'zeta' => '457',                         # U+0x03B6
        'eta' => '632',                          # U+0x03B7
        'theta' => '624',                        # U+0x03B8
        'iota' => '274',                         # U+0x03B9
        'kappa' => '591',                        # U+0x03BA
        'lambda' => '591',                       # U+0x03BB
        'nu' => '591',                           # U+0x03BD
        'xi' => '502',                           # U+0x03BE
        'omicron' => '606',                      # U+0x03BF
        'pi' => '637',                           # U+0x03C0
        'rho' => '625',                          # U+0x03C1
        'sigma1' => '507',                       # U+0x03C2
        'sigma' => '630',                        # U+0x03C3
        'tau' => '496',                          # U+0x03C4
        'upsilon' => '631',                      # U+0x03C5
        'phi' => '790',                          # U+0x03C6
        'chi' => '589',                          # U+0x03C7
        'psi' => '821',                          # U+0x03C8
        'omega' => '813',                        # U+0x03C9
        'iotadieresis' => '274',                 # U+0x03CA
        'upsilondieresis' => '631',              # U+0x03CB
        'omicrontonos' => '606',                 # U+0x03CC
        'upsilontonos' => '631',                 # U+0x03CD
        'omegatonos' => '813',                   # U+0x03CE
        'afii10023' => '632',                    # U+0x0401
        'afii10051' => '792',                    # U+0x0402
        'afii10052' => '566',                    # U+0x0403
        'afii10053' => '700',                    # U+0x0404
        'afii10054' => '683',                    # U+0x0405
        'afii10055' => '420',                    # U+0x0406
        'afii10056' => '420',                    # U+0x0407
        'afii10057' => '454',                    # U+0x0408
        'afii10058' => '1118',                   # U+0x0409
        'afii10059' => '1103',                   # U+0x040A
        'afii10060' => '817',                    # U+0x040B
        'afii10061' => '692',                    # U+0x040C
        'afii10062' => '615',                    # U+0x040E
        'afii10145' => '751',                    # U+0x040F
        'afii10017' => '683',                    # U+0x0410
        'afii10018' => '685',                    # U+0x0411
        'afii10019' => '685',                    # U+0x0412
        'afii10020' => '566',                    # U+0x0413
        'afii10021' => '745',                    # U+0x0414
        'afii10022' => '632',                    # U+0x0415
        'afii10024' => '973',                    # U+0x0416
        'afii10025' => '615',                    # U+0x0417
        'afii10026' => '750',                    # U+0x0418
        'afii10027' => '750',                    # U+0x0419
        'afii10028' => '692',                    # U+0x041A
        'afii10029' => '734',                    # U+0x041B
        'afii10030' => '842',                    # U+0x041C
        'afii10031' => '751',                    # U+0x041D
        'afii10032' => '787',                    # U+0x041E
        'afii10033' => '751',                    # U+0x041F
        'afii10034' => '603',                    # U+0x0420
        'afii10035' => '698',                    # U+0x0421
        'afii10036' => '616',                    # U+0x0422
        'afii10037' => '615',                    # U+0x0423
        'afii10038' => '818',                    # U+0x0424
        'afii10039' => '685',                    # U+0x0425
        'afii10040' => '761',                    # U+0x0426
        'afii10041' => '711',                    # U+0x0427
        'afii10042' => '1030',                   # U+0x0428
        'afii10043' => '1044',                   # U+0x0429
        'afii10044' => '783',                    # U+0x042A
        'afii10045' => '920',                    # U+0x042B
        'afii10046' => '680',                    # U+0x042C
        'afii10047' => '701',                    # U+0x042D
        'afii10048' => '1034',                   # U+0x042E
        'afii10049' => '706',                    # U+0x042F
        'afii10065' => '600',                    # U+0x0430
        'afii10066' => '614',                    # U+0x0431
        'afii10067' => '594',                    # U+0x0432
        'afii10068' => '471',                    # U+0x0433
        'afii10069' => '621',                    # U+0x0434
        'afii10070' => '595',                    # U+0x0435
        'afii10072' => '797',                    # U+0x0436
        'afii10073' => '524',                    # U+0x0437
        'afii10074' => '640',                    # U+0x0438
        'afii10075' => '640',                    # U+0x0439
        'afii10076' => '591',                    # U+0x043A
        'afii10077' => '620',                    # U+0x043B
        'afii10078' => '696',                    # U+0x043C
        'afii10079' => '637',                    # U+0x043D
        'afii10080' => '606',                    # U+0x043E
        'afii10081' => '637',                    # U+0x043F
        'afii10082' => '623',                    # U+0x0440
        'afii10083' => '534',                    # U+0x0441
        'afii10084' => '496',                    # U+0x0442
        'afii10085' => '591',                    # U+0x0443
        'afii10086' => '840',                    # U+0x0444
        'afii10087' => '591',                    # U+0x0445
        'afii10088' => '644',                    # U+0x0446
        'afii10089' => '605',                    # U+0x0447
        'afii10090' => '875',                    # U+0x0448
        'afii10091' => '887',                    # U+0x0449
        'afii10092' => '640',                    # U+0x044A
        'afii10093' => '794',                    # U+0x044B
        'afii10094' => '570',                    # U+0x044C
        'afii10095' => '546',                    # U+0x044D
        'afii10096' => '838',                    # U+0x044E
        'afii10097' => '599',                    # U+0x044F
        'afii10071' => '595',                    # U+0x0451
        'afii10099' => '632',                    # U+0x0452
        'afii10100' => '471',                    # U+0x0453
        'afii10101' => '546',                    # U+0x0454
        'afii10102' => '520',                    # U+0x0455
        'afii10103' => '274',                    # U+0x0456
        'afii10104' => '274',                    # U+0x0457
        'afii10105' => '344',                    # U+0x0458
        'afii10106' => '914',                    # U+0x0459
        'afii10107' => '914',                    # U+0x045A
        'afii10108' => '632',                    # U+0x045B
        'afii10109' => '591',                    # U+0x045C
        'afii10110' => '591',                    # U+0x045E
        'afii10193' => '637',                    # U+0x045F
        'afii10050' => '566',                    # U+0x0490
        'afii10098' => '471',                    # U+0x0491
        'Wgrave' => '988',                       # U+0x1E80
        'wgrave' => '818',                       # U+0x1E81
        'Wacute' => '988',                       # U+0x1E82
        'wacute' => '818',                       # U+0x1E83
        'Wdieresis' => '988',                    # U+0x1E84
        'wdieresis' => '818',                    # U+0x1E85
        'Ygrave' => '615',                       # U+0x1EF2
        'ygrave' => '591',                       # U+0x1EF3
        'afii00208' => '1000',                   # U+0x2015
        'underscoredbl' => '635',                # U+0x2017
        'quotereversed' => '268',                # U+0x201B
        'minute' => '361',                       # U+0x2032
        'second' => '557',                       # U+0x2033
        'exclamdbl' => '624',                    # U+0x203C
        'fraction' => '361',                     # U+0x2044
        'nsuperior' => '545',                    # U+0x207F
        'franc' => '635',                        # U+0x20A3
        'peseta' => '1163',                      # U+0x20A7
        'dong' => '623',                         # U+0x20AB
        'afii61248' => '1076',                   # U+0x2105
        'afii61289' => '323',                    # U+0x2113
        'afii61352' => '1171',                   # U+0x2116
        'estimated' => '717',                    # U+0x212E
# gimel was 0 width, still doesn't show up
        'gimel' => '620',                        # U+0x2137
        'oneeighth' => '1000',                   # U+0x215B
        'threeeighths' => '1000',                # U+0x215C
        'fiveeighths' => '1000',                 # U+0x215D
        'seveneighths' => '1000',                # U+0x215E
        'partialdiff' => '635',                  # U+0x2202
        'product' => '818',                      # U+0x220F
        'summation' => '727',                    # U+0x2211
        'minus' => '818',                        # U+0x2212
        'radical' => '818',                      # U+0x221A
        'infinity' => '1000',                    # U+0x221E
        'integral' => '635',                     # U+0x222B
        'approxequal' => '818',                  # U+0x2248
        'notequal' => '818',                     # U+0x2260
        'lessequal' => '818',                    # U+0x2264
        'greaterequal' => '818',                 # U+0x2265
        'H22073' => '604',                       # U+0x25A1
        'H18543' => '354',                       # U+0x25AA
        'H18551' => '354',                       # U+0x25AB
        'lozenge' => '818',                      # U+0x25CA
        'H18533' => '604',                       # U+0x25CF
        'openbullet' => '354',                   # U+0x25E6
        'commaaccent' => '210',                  # U+0xF6C3
        'radicalex' => '635',                    # U+0xF8E5
        'fi' => '625',                           # U+0xFB01
        'fl' => '625',                           # U+0xFB02
    }, # HORIZ. WIDTH TABLE
} };

1;
