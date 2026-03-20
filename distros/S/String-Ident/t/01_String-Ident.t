#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use utf8;

use Test::Most;

use_ok('String::Ident') or die;

subtest 'non-OO usage' => sub {
    my $ident = String::Ident->cleanup('');
    is( length($ident), 4, 'default min length 4' );
    is( length( String::Ident->cleanup( 'x' x 100 ) ),
        30, 'default max length 30' );
    is( String::Ident->cleanup('Hěλλo wœřľδ!'),
        'Hello-woerld', 'unidecode' );

    is( length( String::Ident->cleanup( 'x' x 100, 42 ) ),
        42, 'custom max length 42' );
    is( length( String::Ident->cleanup( 'x' x 100, -1 ) ),
        100, 'do not truncate' );

    is( String::Ident->cleanup(
            "some very long töxt Lorem ipsum dolor sit amet, consectetur adipiscing elit, ",
            20
        ),
        'some-very-long-toxt-',
        'docu truncate 20'
    );

    is( String::Ident->cleanup(
            "some very long töxt Lorem ipsum dolor sit amet, consectetur adipiscing elit, ",
            -1
        ),
        'some-very-long-toxt-Lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit',
        'docu do not truncate'
    );
};

subtest 'OO usage' => sub {
    my $s_ident = String::Ident->new( min_len => 5, max_len => 10 );
    is( $s_ident->cleanup('Hěλλo wœřľδ!'),
        'Hello-woer', 'unidecode' );
    is( length( $s_ident->cleanup('ABC') ), 5, 'custom min length 5' );
    is( length( $s_ident->cleanup( 'x' x 100 ) ),
        10, 'custom max length 10' );

    my $s_ident2 = String::Ident->new( min_len => -1, max_len => -1 );
    is( length( $s_ident2->cleanup('') ), 0, 'custom min length -1' );
    is( length( $s_ident2->cleanup( 'x' x 100 ) ),
        100, 'custom max length -1' );
};

done_testing();
