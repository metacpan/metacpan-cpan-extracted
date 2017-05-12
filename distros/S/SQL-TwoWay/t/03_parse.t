use strict;
use warnings;
use utf8;
use Test::More;
use SQL::TwoWay;
use Test::Difflet qw/is_deeply/;

sub VARIABLE () { SQL::TwoWay::VARIABLE }
sub SQL      () { SQL::TwoWay::SQL      }
sub IF       () { SQL::TwoWay::IF       }
sub END_     () { SQL::TwoWay::END_     }
sub ELSE     () { SQL::TwoWay::ELSE     }

sub parse {
    my $tokens = SQL::TwoWay::tokenize_two_way_sql($_[0]);
    my $ast = SQL::TwoWay::parse_two_way_sql($tokens);
    return $ast;
}

is_deeply(
    parse(
        'SELECT * FROM foo /* IF $var */v=/* $var */3/* END */'
    ),
    [
        [SQL, 'SELECT * FROM foo '],
        [IF, 'var',
             [[SQL, 'v='],
            [VARIABLE, 'var']],
            [],
             ]
    ],
    'IF'
);

is_deeply(
    parse(
        'SELECT * FROM foo /* IF $var */3/* END */'
    ),
    [
        [SQL, 'SELECT * FROM foo '],
        [IF, 'var',
             [[SQL, '3']],
             []]
    ],
    'IF'
);

is_deeply(
    parse(
        'SELECT * FROM foo WHERE n=/* IF $var */3/* ELSE */4/* END */'
    ),
    [
        [SQL, 'SELECT * FROM foo WHERE n='],
        [IF, 'var',
             [[SQL, '3']],
             [[SQL, '4']]],
    ],
    'IF-ELSE'
);

is_deeply(
    parse(
        'SELECT * FROM foo'
    ),
    [
        [SQL, 'SELECT * FROM foo']
    ],
    'Simple'
);


done_testing;

