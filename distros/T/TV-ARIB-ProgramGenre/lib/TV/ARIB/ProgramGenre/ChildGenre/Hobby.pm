package TV::ARIB::ProgramGenre::ChildGenre::Hobby;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        '旅・釣り・アウトドア',     # 0x0
        '園芸・ペット・手芸',       # 0x1
        '音楽・美術・工芸',         # 0x2
        '囲碁・将棋',               # 0x3
        '麻雀・パチンコ',           # 0x4
        '車・オートバイ',           # 0x5
        'コンピュータ・ＴＶゲーム', # 0x6
        '会話・語学',               # 0x7
        '幼児・小学生',             # 0x8
        '中学生・高校生',           # 0x9
        '大学生・受験',             # 0xA
        '生涯教育・資格',           # 0xB
        '教育問題',                 # 0xC
        '',                         # 0xD
        '',                         # 0xE
        'その他',                   # 0xF
    ];
}

1;

