package TV::ARIB::ProgramGenre::ChildGenre::Welfare;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        '高齢者',       # 0x0
        '障害者',       # 0x1
        '社会福祉',     # 0x2
        'ボランティア', # 0x3
        '手話',         # 0x4
        '文字（字幕）', # 0x5
        '音声解説',     # 0x6
        '',             # 0x7
        '',             # 0x8
        '',             # 0x9
        '',             # 0xA
        '',             # 0xB
        '',             # 0xC
        '',             # 0xD
        '',             # 0xE
        'その他',       # 0xF
    ];
}

1;

