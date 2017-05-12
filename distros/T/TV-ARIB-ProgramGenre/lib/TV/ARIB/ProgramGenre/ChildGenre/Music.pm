package TV::ARIB::ProgramGenre::ChildGenre::Music;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        '国内ロック・ポップス',           # 0x0
        '海外ロック・ポップス',           # 0x1
        'クラシック・オペラ',             # 0x2
        'ジャズ・フュージョン',           # 0x3
        '歌謡曲・演歌',                   # 0x4
        'ライブ・コンサート',             # 0x5
        'ランキング・リクエスト',         # 0x6
        'カラオケ・のど自慢',             # 0x7
        '民謡・邦楽',                     # 0x8
        '童謡・キッズ',                   # 0x9
        '民族音楽・ワールドミュージック', # 0xA
        '',                               # 0xB
        '',                               # 0xC
        '',                               # 0xD
        '',                               # 0xE
        'その他',                         # 0xF
    ];
}

1;

