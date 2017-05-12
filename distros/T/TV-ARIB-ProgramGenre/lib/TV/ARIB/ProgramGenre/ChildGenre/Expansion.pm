package TV::ARIB::ProgramGenre::ChildGenre::Expansion;
use strict;
use warnings;
use utf8;
use parent qw/TV::ARIB::ProgramGenre::ChildGenre/;

sub CHILD_GENRES {
    return [
        'BS/地上デジタル放送用番組付属情報', # 0x0
        '広帯域 CS デジタル放送用拡張',      # 0x1
        '',                                  # 0x2
        'サーバー型番組付属情報',            # 0x3
        'IP 放送用番組付属情報',             # 0x4
        '',                                  # 0x5
        '',                                  # 0x6
        '',                                  # 0x7
        '',                                  # 0x8
        '',                                  # 0x9
        '',                                  # 0xA
        '',                                  # 0xB
        '',                                  # 0xC
        '',                                  # 0xD
        '',                                  # 0xE
        '',                                  # 0xF
    ];
}

1;

