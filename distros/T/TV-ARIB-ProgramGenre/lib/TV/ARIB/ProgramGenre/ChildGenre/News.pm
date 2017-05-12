package TV::ARIB::ProgramGenre::ChildGenre::News;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        '定時・総合',         # 0x0
        '天気',               # 0x1
        '特集・ドキュメント', # 0x2
        '政治・国会',         # 0x3
        '経済・市況',         # 0x4
        '海外・国際',         # 0x5
        '解説',               # 0x6
        '討論・会談',         # 0x7
        '報道特番',           # 0x8
        'ローカル・地域',     # 0x9
        '交通',               # 0xA
        '',                   # 0xB
        '',                   # 0xC
        '',                   # 0xD
        '',                   # 0xE
        'その他',             # 0xF
    ];
}

1;

