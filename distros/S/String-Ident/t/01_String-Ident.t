#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use utf8;

use Test::More;

use_ok('String::Ident') or die;

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

done_testing();
