package TV::ARIB::ProgramGenre::ChildGenre::Sport;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        'スポーツニュース',           # 0x0
        '野球',                       # 0x1
        'サッカー',                   # 0x2
        'ゴルフ',                     # 0x3
        'その他の球技',               # 0x4
        '相撲・格闘技',               # 0x5
        'オリンピック・国際大会',     # 0x6
        'マラソン・陸上・水泳',       # 0x7
        'モータースポーツ',           # 0x8
        'マリン・ウィンタースポーツ', # 0x9
        '競馬・公営競技',             # 0xA
        '',                           # 0xB
        '',                           # 0xC
        '',                           # 0xD
        '',                           # 0xE
        'その他',                     # 0xF
    ];
}

1;

