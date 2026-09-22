######################################################################
#
# EXCERPT -- corpus fixture for Perl500503Syntax-OrDie, not a usable copy
# of the module it was taken from.
#
# Source: Jacode4e::RoundTrip 2.13.81.15
# 13539 of 14207 lines removed.
#
# Only lines the OrDie masker renders as dead were removed: POD bodies,
# non-interpolating heredoc bodies, data tables and everything after
# __END__.  Lines inside a regex literal or an interpolating string
# literal were kept, because stages 3 and 4 read those; so were POD
# directives, heredoc terminators, __END__ and three lines of context on
# each side of every removed run, so that the file still parses and still
# reads as the source it came from.
#
# The reduction is verified to be scanner-neutral: the masked live code,
# the list of regex bodies and the list of string bodies are byte-identical
# to the full source.  See t/0011-corpus-excerpt.t.
#
######################################################################
package Jacode4e::RoundTrip;
$VERSION = '2.13.81.15';
'有朋自遠方来不亦楽乎'=~/^\xE6\x9C\x89/ or die "Perl script '@{[__FILE__]}' must be UTF-8 encoding.\n";
# 如果您可以阅读此字符，则可以通过选择所有内容并将其保存为文件名“Jacode4e/RoundTrip.pm”来将其用作模块。
# 如果您可以閱讀此字符，則可以通過選擇所有內容並將其保存為文件名“Jacode4e/RoundTrip.pm”來將其用作模塊。
# この文字が読める場合は、内容を全て選択してファイル名を "Jacode4e/RoundTrip.pm" にして保存すればそのままモジュールとして利用することができます。
# 이 문자를 읽을 수 있는 경우는, 내용을 모두 선택해 파일명을 "Jacode4e/RoundTrip.pm" 로 해 보존하면 그대로 모듈로서 이용할 수가 있습니다.
# But that is very far into the future isn't it?
######################################################################
#
# Jacode4e::RoundTrip - Converts JIS X 0213 Encodings with Round-Trip
#
# Copyright (c) 2018, 2019, 2021, 2022, 2023, 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;

my %tr = ();
my @encodings = qw(
    cp932x
    cp932
    cp932ibm
    utf8
    utf8.1
    utf8jp
);
my @io_encodings = grep( ! /^(?:unicode)$/, @encodings);

if ($0 eq __FILE__) {
    if (not @ARGV) {
        die <<END;

usage:
    perl $0 --dumptable

END
    }
}

#---------------------------------------------------------------------
# make DBCS codepoints
#---------------------------------------------------------------------
sub dbcs {
    my @dbcs = ();
    for my $octet1 (@{$_[0]}) {
        for my $octet2 (@{$_[1]}) {
            push @dbcs, pack('CC', $octet1, $octet2);
        }
    }
    return @dbcs;
}

#---------------------------------------------------------------------
# make DBCS codepoints JIPS(E)
#---------------------------------------------------------------------
sub dbcs_jipse {
    my @dbcs = ();

    # JIPS(J) --> JIPS(E) table
    # https://ameblo.jp/geckoman/entry-11634710872.html
    my @jtoe = (
        0x00,0x01,0x02,0x03,0x37,0x2D,0x2E,0x2F,0x16,0x05,0x15,0x0B,0x0C,0x0D,0x0E,0x0F, # 0
        0x10,0x11,0x12,0x13,0x3C,0x3D,0x32,0x26,0x18,0x19,0x3F,0x27,0x1C,0x1D,0x1E,0x1F, # 1
        0x40,0x4F,0x7F,0x7B,0xE0,0x6C,0x50,0x7D,0x4D,0x5D,0x5C,0x4E,0x6B,0x60,0x4B,0x61, # 2
        0xF0,0xF1,0xF2,0xF3,0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0x7A,0x5E,0x4C,0x7E,0x6E,0x6F, # 3
        0x7C,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7,0xC8,0xC9,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6, # 4
        0xD7,0xD8,0xD9,0xE2,0xE3,0xE4,0xE5,0xE6,0xE7,0xE8,0xE9,0x4A,0x5B,0x5A,0x5F,0x6D, # 5
        0x79,0x57,0x59,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x70,0x71,0x72,0x73,0x74, # 6
        0x75,0x76,0x77,0x78,0x80,0x8B,0x9B,0x9C,0xA0,0xAB,0xB0,0xC0,0x6A,0xD0,0xA1,0x00, # 7
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, # 8
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, # 9
        0x00,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x51,0x52,0x53,0x54,0x55,0x56, # A
        0x58,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8A,0x8C,0x8D,0x8E,0x8F,0x90, # B
        0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9A,0x9D,0x9E,0x9F,0xA2,0xA3,0xA4, # C
        0xA5,0xA6,0xA7,0xA8,0xA9,0xAA,0xAC,0xAD,0xAE,0xAF,0xBA,0xBB,0xBC,0xBD,0xBE,0xBF, # D
        0xB2,0xB3,0xB4,0xB5,0xB6,0xB7,0xB8,0xB9,0xCA,0xCB,0xCC,0xCD,0xCE,0xCF,0xDA,0xDB, # E
        0xDC,0xDD,0xDE,0xDF,0xEA,0xEB,0xEC,0xED,0xEE,0xEF,0xFA,0xFB,0xFC,0xFD,0xFE,0x00, # F
    );

    for my $octet1 (@{$_[0]}) {
        for my $octet2 (@{$_[1]}) {
            push @dbcs, pack('CC', $jtoe[$octet1], $jtoe[$octet2]);
        }
    }
    return @dbcs;
}

#------------------------------------------------------------------------------------------------------------------
# CP00930 User-defined Area: ([\x69-\x71][\x41-\xFE]|[\x72][\x41-\xEA])
#
#------------------------------------------------------------------------------------------------------------------

my %userarea = ();
@{$userarea{'cp00930'}} = (dbcs([0x69..0x71],[0x41..0xFE]), dbcs([0x72],[0x41..0xEA]));
@{$userarea{'keis78'}}  =
@{$userarea{'keis83'}}  =
@{$userarea{'keis90'}}  = (dbcs([0x81..0x9E,0xA0],[0xA1..0xFE]), dbcs([0x41..0x80],[0xA1..0xFE]), dbcs([0x41..0xFE],[0x41..0xA0]));
@{$userarea{'jef'}}     = (dbcs([0x80..0xA0],[0xA1..0xFE]));
@{$userarea{'jipsj'}}   = (dbcs      ([0x74..0x7E],[0x21..0x7E]), dbcs      ([0xE0..0xFE],[0xA1..0xFE]));
@{$userarea{'jipse'}}   = (dbcs_jipse([0x74..0x7E],[0x21..0x7E]), dbcs_jipse([0xE0..0xFE],[0xA1..0xFE]));
@{$userarea{'letsj'}}   = (dbcs([0x31..0x40,0x6D..0x78],[0xA1..0xFE]));
@{$userarea{'utf8'}}    = (map { "\xEF" . $_ } dbcs([0x80..0xBF],[0x80..0xBF]));

while (<DATA>) {
    next if /^#/;
    chomp;

    my %hex = ();
    @hex{@encodings} = split(/ +/,$_);

    my %bin = ();
    for my $encoding (@io_encodings) {
        $bin{$encoding} = (($hex{$encoding} =~ /^[0123456789ABCDEF]+$/) ? pack('H*', $hex{$encoding}) : '');
    }

    for my $encoding (@io_encodings) {
        if ($bin{'utf8jp'} ne '') {
            if ($bin{$encoding} ne '') {
                if ($encoding eq 'utf8jp') {
                }
                elsif (defined($tr{'utf8jp'}{$encoding}{$bin{$encoding}}) and ($tr{'utf8jp'}{$encoding}{$bin{$encoding}} ne '')) {
                    die qq{@{[__FILE__]} duplicate definitions \$tr{'utf8jp'}{'$encoding'}{'$hex{$encoding}'} = "$hex{utf8}($bin{utf8})" and "} . uc unpack('H*',$tr{'utf8jp'}{$encoding}{$bin{$encoding}}) . qq{"($tr{'utf8jp'}{$encoding}{$bin{$encoding}})\n};
                }
                elsif (defined($tr{$encoding}{'utf8jp'}{$bin{'utf8jp' }}) and ($tr{$encoding}{'utf8jp'}{$bin{'utf8jp' }} ne '')) {
                    die qq{@{[__FILE__]} duplicate definitions \$tr{'$encoding'}{'utf8jp'}{'$hex{utf8}'} = "$hex{$encoding}" and "} . uc unpack('H*',$tr{$encoding}{'utf8jp'}{$bin{'utf8jp'}})    . qq{"\n};
                }

                $tr{'utf8jp'}{$encoding}{$bin{$encoding}} = $bin{'utf8jp'};
                $tr{$encoding}{'utf8jp'}{$bin{'utf8jp'} } = $bin{$encoding};
            }
            elsif (exists $userarea{$encoding}) {
                if (my $bin_encoding = shift(@{$userarea{$encoding}})) {
                    $tr{'utf8jp'}{$encoding}{$bin_encoding}  = $bin{'utf8jp'};
                    $tr{$encoding}{'utf8jp'}{$bin{'utf8jp'}} = $bin_encoding;
                }
                else {
                    die qq{@{[__FILE__]} User area of '$encoding' is not enough\n};
                }
            }
        }
    }
}

my $data_count = scalar(keys %{$tr{'utf8jp'}{'utf8jp'}});
if ($data_count != 11578) {
    die qq{@{[__FILE__]} is probably broken(data_count=$data_count).\n};
}

my %Knowledge_Base_Article_ID_170559_prb_conversion_problem_between_shift_jis_and_unicode = ();
for (split /\n/, <<'END') {
# https://support.microsoft.com/ja-jp/help/170559/prb-conversion-problem-between-shift-jis-and-unicode
# CodePage 932 : 398 non-round-trip mappings
0x8790   -> U+2252   -> 0x81e0   Approximately Equal To Or The Image Of
0xfa5a   -> U+2121   -> 0x8784   Telephone Sign
0xfa5b   -> U+2235   -> 0x81e6   Because
END
    next if /^#/;
    if (my($cp932a, $Unicode, $cp932b) = / 0x([0123456789abcdef]{4}) .+? U\+([0123456789abcdef]{4}) .+? 0x([0123456789abcdef]{4}) /x) {
        $Knowledge_Base_Article_ID_170559_prb_conversion_problem_between_shift_jis_and_unicode{ pack('H*',uc($cp932a)) } = pack('H*',uc($cp932b));
    }
}

my %x = (

    # utf8jp(UTF-8-SPUA-JP) is best choice as internal encoding, because it
    # makes one character by one code point on fixed length without grapheme
    # clustering.
    # Other all are not so.

    'cp932x' => {
        'get_ctype' => sub { m!^[^\x81-\x9F\xE0-\xFC]! ? 'SBCS' : m!^[\x81-\x9F\xE0-\xFC]! ? 'DBCS' : undef },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^((?:\x9C\x5A)?[\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'cp932x'}{$Knowledge_Base_Article_ID_170559_prb_conversion_problem_between_shift_jis_and_unicode{$_[0]}||$_[0]} },
        'putc'      => sub { local $^W; $tr{'cp932x'}{'utf8jp'}{$_[0]} },
    },
    'cp932' => {
        'get_ctype' => sub { m!^[^\x81-\x9F\xE0-\xFC]! ? 'SBCS' : m!^[\x81-\x9F\xE0-\xFC]! ? 'DBCS' : undef },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'cp932'}{$Knowledge_Base_Article_ID_170559_prb_conversion_problem_between_shift_jis_and_unicode{$_[0]}||$_[0]} },
        'putc'      => sub { local $^W; $tr{'cp932'}{'utf8jp'}{$_[0]} },
    },
    'cp932ibm' => {
        'get_ctype' => sub { m!^[^\x81-\x9F\xE0-\xFC]! ? 'SBCS' : m!^[\x81-\x9F\xE0-\xFC]! ? 'DBCS' : undef },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
#       'getc'      => sub { local $^W; $tr{'utf8jp'}{'cp932ibm'}{$_[0]} },
#                                                      VVVVVVVV--- 'cp932' with KB170559 is better than only 'cp932ibm' on read
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'cp932'   }{$Knowledge_Base_Article_ID_170559_prb_conversion_problem_between_shift_jis_and_unicode{$_[0]}||$_[0]} },
        'putc'      => sub { local $^W; $tr{'cp932ibm'}{'utf8jp'}{$_[0]} },
    },
    'cp932nec' => {
        'get_ctype' => sub { m!^[^\x81-\x9F\xE0-\xFC]! ? 'SBCS' : m!^[\x81-\x9F\xE0-\xFC]! ? 'DBCS' : undef },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
#       'getc'      => sub { local $^W; $tr{'utf8jp'}{'cp932nec'}{$_[0]} },
#                                                      VVVVVVVV--- 'cp932' with KB170559 is better than only 'cp932nec' on read
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'cp932'   }{$Knowledge_Base_Article_ID_170559_prb_conversion_problem_between_shift_jis_and_unicode{$_[0]}||$_[0]} },
        'putc'      => sub { local $^W; $tr{'cp932nec'}{'utf8jp'}{$_[0]} },
    },
    'sjis2004' => {
        'get_ctype' => sub { m!^[^\x81-\x9F\xE0-\xFC]! ? 'SBCS' : m!^[\x81-\x9F\xE0-\xFC]! ? 'DBCS' : undef },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'sjis2004'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'sjis2004'}{'utf8jp'}{$_[0]} },
    },
    'cp00930' => {
        'get_ctype' => sub { s!^\x0F!! ? 'SBCS' : s!^\x0E!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x0F", 'DBCS'=>"\x0E", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'cp00930'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'cp00930'}{'utf8jp'}{$_[0]} },
    },
    'keis78' => {
        'get_ctype' => sub { s!^\x0A\x41!! ? 'SBCS' : s!^\x0A\x42!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x0A\x41", 'DBCS'=>"\x0A\x42", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'keis78'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'keis78'}{'utf8jp'}{$_[0]} },
    },
    'keis83' => {
        'get_ctype' => sub { s!^\x0A\x41!! ? 'SBCS' : s!^\x0A\x42!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x0A\x41", 'DBCS'=>"\x0A\x42", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'keis83'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'keis83'}{'utf8jp'}{$_[0]} },
    },
    'keis90' => {
        'get_ctype' => sub { s!^\x0A\x41!! ? 'SBCS' : s!^\x0A\x42!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x0A\x41", 'DBCS'=>"\x0A\x42", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'keis90'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'keis90'}{'utf8jp'}{$_[0]} },
    },
    'jef' => {
        'get_ctype' => sub { s!^\x29!! ? 'SBCS' : s!^[\x28\x38]!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x29", 'DBCS'=>"\x28", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'jef'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'jef'}{'utf8jp'}{$_[0]} },
    },
    'jef9p' => {
        'get_ctype' => sub { s!^\x29!! ? 'SBCS' : s!^[\x28\x38]!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x29", 'DBCS'=>"\x38", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'jef'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'jef'}{'utf8jp'}{$_[0]} },
    },
    'jipsj' => {
        'get_ctype' => sub { s!^\x1A\x71!! ? 'SBCS' : s!^\x1A\x70!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x1A\x71", 'DBCS'=>"\x1A\x70", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'jipsj'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'jipsj'}{'utf8jp'}{$_[0]} },
    },
    'jipse' => {
        'get_ctype' => sub { s!^\x3F\x76!! ? 'SBCS' : s!^\x3F\x75!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x3F\x76", 'DBCS'=>"\x3F\x75", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'jipse'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'jipse'}{'utf8jp'}{$_[0]} },
    },
    'letsj' => {
        'get_ctype' => sub { s!^\x93\xF1!! ? 'SBCS' : s!^\x93\x70!! ? 'DBCS' : undef },
        'set_ctype' => sub { {'SBCS'=>"\x93\xF1", 'DBCS'=>"\x93\x70", }->{$_[0]} },
        'getoct'    => sub { $_[0] eq 'SBCS' ? s!^([\x00-\xFF])!! : s!^([\x00-\xFF]{1,2})!!; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'letsj'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'letsj'}{'utf8jp'}{$_[0]} },
    },
    'utf8' => {
        'get_ctype' => sub { m!^[\x00-\x7F\xFE\xFF]! ? 'SBCS' : m!^[^\x00-\x7F\xFE\xFF]! ? 'DBCS' : undef },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { s!^(
            [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF] |
            [\xE0-\xE2\xE4-\xEF][\x80-\xBF]{2}     |
            \xE3(?:
                \x81\x8B\xE3\x82\x9A               | # U+304B+309A
                \x81\x8D\xE3\x82\x9A               | # U+304D+309A
                \x81\x8F\xE3\x82\x9A               | # U+304F+309A
                \x81\x91\xE3\x82\x9A               | # U+3051+309A
                \x81\x93\xE3\x82\x9A               | # U+3053+309A
                \x82\xAB\xE3\x82\x9A               | # U+30AB+309A
                \x82\xAD\xE3\x82\x9A               | # U+30AD+309A
                \x82\xAF\xE3\x82\x9A               | # U+30AF+309A
                \x82\xB1\xE3\x82\x9A               | # U+30B1+309A
                \x82\xB3\xE3\x82\x9A               | # U+30B3+309A
                \x82\xBB\xE3\x82\x9A               | # U+30BB+309A
                \x83\x84\xE3\x82\x9A               | # U+30C4+309A
                \x83\x88\xE3\x82\x9A               | # U+30C8+309A
                \x87\xB7\xE3\x82\x9A               | # U+31F7+309A
                [\x80-\xBF]{2}
            )                                      |
            [\xC2\xC4-\xC8\xCC-\xDF][\x80-\xBF]    |
            \xC3(?:
                \xA6\xCC\x80                       | # U+00E6+0300
                [\x80-\xBF]
            )                                      |
            \xC9(?:
                \x94\xCC\x80                       | # U+0254+0300
                \x94\xCC\x81                       | # U+0254+0301
                \x99\xCC\x80                       | # U+0259+0300
                \x99\xCC\x81                       | # U+0259+0301
                \x9A\xCC\x80                       | # U+025A+0300
                \x9A\xCC\x81                       | # U+025A+0301
                [\x80-\xBF]
            )                                      |
            \xCA(?:
                \x8C\xCC\x80                       | # U+028C+0300
                \x8C\xCC\x81                       | # U+028C+0301
                [\x80-\xBF]
            )                                      |
            \xCB(?:
                \xA5\xCB\xA9                       | # U+02E5+02E9
                \xA9\xCB\xA5                       | # U+02E9+02E5
                [\x80-\xBF]
            )                                      |
            [\xF0-\xF4][\x80-\xBF]{3}              |
            [\x00-\xFF]
        )!!xs; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'utf8'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'utf8'}{'utf8jp'}{$_[0]} },
    },
    'utf8.1' => {
        'get_ctype' => sub { m!^[\x00-\x7F\xFE\xFF]! ? 'SBCS' : m!^[^\x00-\x7F\xFE\xFF]! ? 'DBCS' : undef },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { s!^(
            [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF] |
            [\xE0-\xE2\xE4-\xEF][\x80-\xBF]{2}     |
            \xE3(?:
                \x81\x8B\xE3\x82\x9A               | # U+304B+309A
                \x81\x8D\xE3\x82\x9A               | # U+304D+309A
                \x81\x8F\xE3\x82\x9A               | # U+304F+309A
                \x81\x91\xE3\x82\x9A               | # U+3051+309A
                \x81\x93\xE3\x82\x9A               | # U+3053+309A
                \x82\xAB\xE3\x82\x9A               | # U+30AB+309A
                \x82\xAD\xE3\x82\x9A               | # U+30AD+309A
                \x82\xAF\xE3\x82\x9A               | # U+30AF+309A
                \x82\xB1\xE3\x82\x9A               | # U+30B1+309A
                \x82\xB3\xE3\x82\x9A               | # U+30B3+309A
                \x82\xBB\xE3\x82\x9A               | # U+30BB+309A
                \x83\x84\xE3\x82\x9A               | # U+30C4+309A
                \x83\x88\xE3\x82\x9A               | # U+30C8+309A
                \x87\xB7\xE3\x82\x9A               | # U+31F7+309A
                [\x80-\xBF]{2}
            )                                      |
            [\xC2\xC4-\xC8\xCC-\xDF][\x80-\xBF]    |
            \xC3(?:
                \xA6\xCC\x80                       | # U+00E6+0300
                [\x80-\xBF]
            )                                      |
            \xC9(?:
                \x94\xCC\x80                       | # U+0254+0300
                \x94\xCC\x81                       | # U+0254+0301
                \x99\xCC\x80                       | # U+0259+0300
                \x99\xCC\x81                       | # U+0259+0301
                \x9A\xCC\x80                       | # U+025A+0300
                \x9A\xCC\x81                       | # U+025A+0301
                [\x80-\xBF]
            )                                      |
            \xCA(?:
                \x8C\xCC\x80                       | # U+028C+0300
                \x8C\xCC\x81                       | # U+028C+0301
                [\x80-\xBF]
            )                                      |
            \xCB(?:
                \xA5\xCB\xA9                       | # U+02E5+02E9
                \xA9\xCB\xA5                       | # U+02E9+02E5
                [\x80-\xBF]
            )                                      |
            [\xF0-\xF4][\x80-\xBF]{3}              |
            [\x00-\xFF]
        )!!xs; $1 },
        'getc'      => sub { local $^W; $tr{'utf8jp'}{'utf8.1'}{$_[0]} },
        'putc'      => sub { local $^W; $tr{'utf8.1'}{'utf8jp'}{$_[0]} },
    },
    'utf8jp' => {
        'get_ctype' => sub { m!^\xF3\xB0(?:[\x80-\x82][\x80-\xBF]|\x83[\x80-\xBE])! ? 'SBCS' : 'DBCS' },
        'set_ctype' => sub { q!! },
        'getoct'    => sub { s!^(\xF3[\xB0-\xB5][\x80-\xBF][\x80-\xBF]|[\x00-\xFF])!!; $1; },
        'getc'      => sub { $_[0] },
        'putc'      => sub { $_[0] },
    },
);

#---------------------------------------------------------------------
# convert encoding to OUTPUT_encoding from INPUT_encoding
#---------------------------------------------------------------------
sub convert {
    local $_            = ${$_[0]};
    my $OUTPUT_encoding = $_[1];
    my $INPUT_encoding  = $_[2];
    my $option          = ($_[3] || {});
    my $last_ctype      = undef;
    my $output          = '';
    my $count           = 0;
    $option->{'OVERRIDE_MAPPING'} ||= {};

    if (ref($_[0]) ne 'SCALAR') {
        die "@{[__FILE__]} \$_[0] isn't scalar reference\n";
    }
    if (not exists $x{$OUTPUT_encoding}) {
        die "@{[__FILE__]} unknown OUTPUT encoding '$OUTPUT_encoding'\n";
    }
    if (not exists $x{$INPUT_encoding}) {
        die "@{[__FILE__]} unknown INPUT encoding '$INPUT_encoding'\n";
    }

    my $INPUT_LAYOUT = undef;
    my @ctype = ();
    if ($INPUT_encoding =~ /^(?:cp932x|cp932|cp932ibm|cp932nec|sjis2004|cp00930|keis78|keis83|keis90|jef|jef9p|jipsj|jipse|letsj)$/) {
        if (defined $option->{'INPUT_LAYOUT'}) {
            $INPUT_LAYOUT = $option->{'INPUT_LAYOUT'};
            $INPUT_LAYOUT =~ s/([SD])([0-9]+)/$1 x $2/ge;
            if ($INPUT_LAYOUT =~ /^[SD]*$/) {
                @ctype = map {{'S'=>'SBCS', 'D'=>'DBCS',}->{$_}} split(//,$INPUT_LAYOUT);
            }
            else {
                die "@{[__FILE__]} INPUT_LAYOUT isn't 'S' or 'D' sequence '$INPUT_LAYOUT'";
            }
        }
    }

    while ($_ ne '') {
        my $ctype = '';
        if (defined $INPUT_LAYOUT) {
            $ctype = (shift(@ctype) || 'SBCS');
        }
        else {
            $ctype = ($x{$INPUT_encoding}{'get_ctype'}->() || $last_ctype || 'SBCS');
        }

        if (not defined($last_ctype) or ($ctype ne $last_ctype)) {
            if ($option->{'OUTPUT_SHIFTING'}) {
                $output .= $x{$OUTPUT_encoding}{'set_ctype'}->($ctype);
            }
            $last_ctype = $ctype;
        }

        my $input_octets = $x{$INPUT_encoding}{'getoct'}->($ctype);
        if (defined $input_octets) {
            if (defined $option->{'OVERRIDE_MAPPING'}{$input_octets}) {
                $output .= $option->{'OVERRIDE_MAPPING'}{$input_octets};
            }
            else {
                my $char = $x{$INPUT_encoding}{'getc'}->($input_octets);
                if (not defined $char) {
                    if (defined $option->{'GETA'}) {
                        $output .= $option->{'GETA'};
                    }
                    else {
                        $output .= $x{$OUTPUT_encoding}{'putc'}->("\xF3\xB0\x85\xAB");
                    }
                }
                elsif ($char eq "\xF3\xB0\x84\x80") {
                    if (defined $option->{'SPACE'}) {
                        $output .= $option->{'SPACE'};
                    }
                    else {
                        $output .= $x{$OUTPUT_encoding}{'putc'}->($char);
                    }
                }
                else {
                    my $output_octets = $x{$OUTPUT_encoding}{'putc'}->($char);
                    if (not defined ($output_octets) or ($output_octets eq '')) {
                        if (defined $option->{'GETA'}) {
                            $output .= $option->{'GETA'};
                        }
                        else {
                            $output .= $x{$OUTPUT_encoding}{'putc'}->("\xF3\xB0\x85\xAB");
                        }
                    }
                    else {
                        $output .= $output_octets;
                    }
                }
            }
        }

        $count++;
    }

    ${$_[0]} = $output;
    return $count;
}

#---------------------------------------------------------------------
# confirm version
#---------------------------------------------------------------------
sub VERSION {
    my($version) = @_;
    if ($version ne $Jacode4e::RoundTrip::VERSION) {
        die "@{[__FILE__]} $Jacode4e::RoundTrip::VERSION isn't $version";
    }
}

#---------------------------------------------------------------------
# dump encoding tables
#---------------------------------------------------------------------
END {
    if (
        ($0 eq __FILE__)  and
        defined($ARGV[0]) and
        ($ARGV[0] eq '--dumptable')
    ) {

        # dump DBCS tables
        for my $encoding (qw(
            cp932 cp932ibm cp932nec sjis2004 cp00930 keis78 keis83 keis90 jef jef9p jipsj jipse letsj
        )) {
            open(FILE,">$0-$Jacode4e::RoundTrip::VERSION.TABLE.\U$encoding\E.txt") || die;
            binmode(FILE);
            for (my $octet1=0x00; $octet1<=0xFF; $octet1+=0x01) {
                for (my $octet2=0x00; $octet2<=0xF0; $octet2+=0x10) {
                    my @line = ();
                    for (my $column=0x00; $column<=0x0F; $column+=0x01) {
                        my $octets = pack('CC', $octet1, $octet2 + $column);
                        Jacode4e::RoundTrip::convert(\$octets, 'utf8', $encoding, { 'INPUT_LAYOUT'=>'D', 'GETA'=>"　" });
                        push @line, $octets;
                    }
                    if (grep(!/　/,@line) >= 1) {
                        printf FILE ('%s %02X%02X: ', uc $encoding, $octet1, $octet2);
                        printf FILE ('%-2s%-2s%-2s%-2s ', $line[ 0], $line[ 1], $line[ 2], $line[ 3]);
                        printf FILE ('%-2s%-2s%-2s%-2s ', $line[ 4], $line[ 5], $line[ 6], $line[ 7]);
                        printf FILE ('%-2s%-2s%-2s%-2s ', $line[ 8], $line[ 9], $line[10], $line[11]);
                        printf FILE ('%-2s%-2s%-2s%-2s ', $line[12], $line[13], $line[14], $line[15]);
                        print  FILE "\n";
                    }
                }
            }
            close(FILE);
        }

        # dump CP932X table
        open(FILE,">$0-$Jacode4e::RoundTrip::VERSION.TABLE.CP932X.txt") || die;
        binmode(FILE);
        for (my $octet1=0x00; $octet1<=0xFF; $octet1+=0x01) {
            for (my $octet2=0x00; $octet2<=0xF0; $octet2+=0x10) {
                my @line = ();
                for (my $column=0x00; $column<=0x0F; $column+=0x01) {
                    my $octets = pack('CC', $octet1, $octet2 + $column);
                    Jacode4e::RoundTrip::convert(\$octets, 'utf8', 'cp932x', { 'INPUT_LAYOUT'=>'D', 'GETA'=>"　" });
                    push @line, $octets;
                }
                for (my $column=0x00; $column<=0x0F; $column+=0x01) {
                    my $octets = pack('CCCC', 0x9C, 0x5A, $octet1, $octet2 + $column);
                    Jacode4e::RoundTrip::convert(\$octets, 'utf8', 'cp932x', { 'INPUT_LAYOUT'=>'D', 'GETA'=>"　" });
                    push @line, $octets;
                }
                if (grep(!/　/,@line) >= 1) {
                    printf FILE ('CP932X %02X%02X: ', $octet1, $octet2);
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[ 0], $line[ 1], $line[ 2], $line[ 3]);
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[ 4], $line[ 5], $line[ 6], $line[ 7]);
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[ 8], $line[ 9], $line[10], $line[11]);
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[12], $line[13], $line[14], $line[15]);
                    print  FILE '  ';
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[16], $line[17], $line[18], $line[19]);
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[20], $line[21], $line[22], $line[23]);
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[24], $line[25], $line[26], $line[27]);
                    printf FILE ('%-2s%-2s%-2s%-2s ', $line[28], $line[29], $line[30], $line[31]);
                    print  FILE "\n";
                }
            }
        }
        close(FILE);

        exit;
    }
}

#---------------------------------------------------------------------
# document
=pod
=encoding utf8
=head1 NAME
=head1 CAUTION
=head1 SYNOPSIS
=head2 $char_count
=head2 $line
=head2 $OUTPUT_encoding
=head2 $INPUT_encoding
=head2 { %option }
=over 2
=item *
=item *
=item *
=item *
=item *
=back
=head1 SAMPLES
=head1 INPUT SI/SO code
=head1 OUTPUT SI/SO code
=head1 OUTPUT DBCS/MBCS SPACE code
=head1 OUTPUT DBCS/MBCS GETA code
=head1 RAISON D'ETRE(Reason For Existence)
=head1 WHAT IS "CP932X"?
=over 4
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head1 WHAT IS "UTF-8-SPUA-JP"?
=over 4
=item *
=item *
=item *
=item *
=item *
=item *
=item *
=back
=head1 CP932 vs. CP932IBM
=head1 CP932 vs. CP932NEC
=head1 UTF-8.0 vs. UTF-8.1
=head1 ERRATAS OF MAPPINGS
=head2 KEIS78, KEIS83, and KEIS90
=head2 JEF and JEF9P
=head2 JIPS(J)
=head2 JIPS(E)
=head1 DEPENDENCIES
=head1 SOFTWARE LIFE CYCLE
=head1 Why and how to CP932X Born?
=over 2
=item *
=item *
=item *
=back
=head1 How To Update This Distribution
=over 2
=item 1
=item 2
=item 3
=item 4
=item 5
=item 6
=item 7
=item 8
=item 9
=back
=head1 AUTHOR
=head1 LICENSE AND COPYRIGHT
=head1 SEE ALSO
=head1 ACKNOWLEDGEMENTS
=head1 HELLO WORLD

=cut

1;

__DATA__
###################################################################################################################
# End of table
###################################################################################################################
