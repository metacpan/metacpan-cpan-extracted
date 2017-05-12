package TV::ARIB::ProgramGenre::ChildGenre::Info;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        '芸能・ワイドショー', # 0x0
        'ファッション',       # 0x1
        '暮らし・住まい',     # 0x2
        '健康・医療',         # 0x3
        'ショッピング・通販', # 0x4
        'グルメ・料理',       # 0x5
        'イベント',           # 0x6
        '番組紹介・お知らせ', # 0x7
        '',                   # 0x8
        '',                   # 0x9
        '',                   # 0xA
        '',                   # 0xB
        '',                   # 0xC
        '',                   # 0xD
        '',                   # 0xE
        'その他',             # 0xF
    ];
}

1;

