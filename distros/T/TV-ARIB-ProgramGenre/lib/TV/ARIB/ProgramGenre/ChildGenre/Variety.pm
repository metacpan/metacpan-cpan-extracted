package TV::ARIB::ProgramGenre::ChildGenre::Variety;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        'クイズ',           # 0x0
        'ゲーム',           # 0x1
        'トークバラエティ', # 0x2
        'お笑い・コメディ', # 0x3
        '音楽バラエティ',   # 0x4
        '旅バラエティ',     # 0x5
        '料理バラエティ',   # 0x6
        '',                 # 0x7
        '',                 # 0x8
        '',                 # 0x9
        '',                 # 0xA
        '',                 # 0xB
        '',                 # 0xC
        '',                 # 0xD
        '',                 # 0xE
        'その他',           # 0xF
    ];
}

1;

