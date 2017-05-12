package TV::ARIB::ProgramGenre::ChildGenre::Documentary;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        '社会・時事',           # 0x0
        '歴史・紀行',           # 0x1
        '自然・動物・環境',     # 0x2
        '宇宙・科学・医学',     # 0x3
        'カルチャー・伝統文化', # 0x4
        '文学・文芸',           # 0x5
        'スポーツ',             # 0x6
        'ドキュメンタリー全般', # 0x7
        'インタビュー・討論',   # 0x8
        '',                     # 0x9
        '',                     # 0xA
        '',                     # 0xB
        '',                     # 0xC
        '',                     # 0xD
        '',                     # 0xE
        'その他',               # 0xF
    ];
}

1;

