#!perl

use strict;
use warnings;
use utf8;
use Encode qw/encode_utf8/;
use TV::ARIB::ProgramGenre qw/get_genre_name get_genre_id get_parent_genre_name get_parent_genre_id/;

use Test::More;

subtest 'get_genre_name' => sub {
    is get_genre_name(0,  0), encode_utf8('定時・総合');
    is get_genre_name(1,  0), encode_utf8('スポーツニュース');
    is get_genre_name(2,  0), encode_utf8('芸能・ワイドショー');
    is get_genre_name(3,  0), encode_utf8('国内ドラマ');
    is get_genre_name(4,  0), encode_utf8('国内ロック・ポップス');
    is get_genre_name(5,  0), encode_utf8('クイズ');
    is get_genre_name(6,  0), encode_utf8('洋画');
    is get_genre_name(7,  0), encode_utf8('国内アニメ');
    is get_genre_name(8,  0), encode_utf8('社会・時事');
    is get_genre_name(9,  0), encode_utf8('現代劇・新劇');
    is get_genre_name(10, 0), encode_utf8('旅・釣り・アウトドア');
    is get_genre_name(11, 0), encode_utf8('高齢者');
    is get_genre_name(12, 0), '';
    is get_genre_name(13, 0), '';
    is get_genre_name(14, 0), encode_utf8('BS/地上デジタル放送用番組付属情報');
    is get_genre_name(15, 0), '';

    subtest 'Error handling' => sub {
        eval { get_genre_name(0) };
        ok $@, 'Not enough argument';
        eval { get_genre_name(16, 0) };
        ok $@, 'Out of parent genre';
        eval { get_genre_name(0, 16) };
        ok $@, 'Out of child genre';
    };
};

subtest 'get_genre_id' => sub {
    is_deeply get_genre_id('天気'),                         [0, 1];
    is_deeply get_genre_id('野球'),                         [1, 1];
    is_deeply get_genre_id('ファッション'),                 [2, 1];
    is_deeply get_genre_id('海外ドラマ'),                   [3, 1];
    is_deeply get_genre_id('海外ロック・ポップス'),         [4, 1];
    is_deeply get_genre_id('ゲーム'),                       [5, 1];
    is_deeply get_genre_id('邦画'),                         [6, 1];
    is_deeply get_genre_id('海外アニメ'),                   [7, 1];
    is_deeply get_genre_id('歴史・紀行'),                   [8, 1];
    is_deeply get_genre_id('ミュージカル'),                 [9, 1];
    is_deeply get_genre_id('園芸・ペット・手芸'),           [10, 1];
    is_deeply get_genre_id('障害者'),                       [11, 1];
    is_deeply get_genre_id('広帯域 CS デジタル放送用拡張'), [14, 1];

    subtest 'Error handling' => sub {
        eval { get_genre_id() };
        ok $@, 'Not enough argument';
        eval { get_genre_id('foobar') };
        ok $@, 'Specfy nonentity genre';
    };
};

subtest 'get_parent_genre_name' => sub {
    is get_parent_genre_name(0), encode_utf8('ニュース／報道');

    subtest 'Error handling' => sub {
        eval { get_parent_genre_name() };
        ok $@, 'Not enough argument';
        eval { get_parent_genre_name(16) };
        ok $@, 'Out of parent genre';
    };
};

subtest 'get_parent_genre_id' => sub {
    is get_parent_genre_id('ニュース／報道'), 0;

    subtest 'Error handling' => sub {
        eval { get_parent_genre_id() };
        ok $@, 'Not enough argument';
        eval { get_parent_genre_id('foobar') };
        ok $@, 'Specfy nonentity genre';
    };
};

done_testing;

