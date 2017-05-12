package TV::ARIB::ProgramGenre::ChildGenre::Theater;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        '現代劇・新劇',   # 0x0
        'ミュージカル',   # 0x1
        'ダンス・バレエ', # 0x2
        '落語・演芸',     # 0x3
        '歌舞伎・古典',   # 0x4
        '',               # 0x5
        '',               # 0x6
        '',               # 0x7
        '',               # 0x8
        '',               # 0x9
        '',               # 0xA
        '',               # 0xB
        '',               # 0xC
        '',               # 0xD
        '',               # 0xE
        'その他',         # 0xF
    ];
}

1;
