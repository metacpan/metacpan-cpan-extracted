use strict;
use warnings;
use utf8;
use Test::More;
use SQL::TwoWay;
use Test::Difflet qw(is_deeply);

sub VARIABLE () { SQL::TwoWay::VARIABLE }
sub SQL      () { SQL::TwoWay::SQL      }
sub IF       () { SQL::TwoWay::IF       }
sub END_     () { SQL::TwoWay::END_     }
sub ELSE     () { SQL::TwoWay::ELSE     }

sub tokenize { SQL::TwoWay::tokenize_two_way_sql(@_) }

ok SQL;
ok VARIABLE;

is_deeply(
    tokenize(
       q{/* IF $f *//* $y */"2"/* END */"2"}
    ),
    [
        [IF, 'f'],
        [VARIABLE, 'y'],
        [END_],
        [SQL, q{"2"}],
    ],
    'error'
);

is_deeply(
    tokenize(
       q{/* IF $f *//* $y */'2'/* END */'2'}
    ),
    [
        [IF, 'f'],
        [VARIABLE, 'y'],
        [END_],
        [SQL, q{'2'}],
    ],
    'error'
);

is_deeply(
    tokenize(
        'SELECT * FROM foo /* IF $var */v=/* $var */3/* END */'
    ),
    [
        [SQL, 'SELECT * FROM foo '],
        [IF, 'var'],
        [SQL, 'v='],
        [VARIABLE, 'var'],
        [END_],
    ],
    'Simple'
);

is_deeply(
    tokenize(
        'SELECT * FROM foo'
    ),
    [
        [SQL, 'SELECT * FROM foo']
    ],
    'Simple'
);

is_deeply(
    tokenize(
        'SELECT * FROM foo WHERE v=/* $v */3'
    ),
    [
        [SQL, 'SELECT * FROM foo WHERE v='],
        [VARIABLE, 'v']
    ],
    'Variable with integer'
);

is_deeply(
    tokenize(
        'SELECT * FROM foo WHERE 1=1 AND /* IF $c */v=/* $v */3/* END */'
    ),
    [
        [SQL, 'SELECT * FROM foo WHERE 1=1 AND '],
        [IF, 'c'],
        [SQL, 'v='],
        [VARIABLE, 'v'],
        [END_],
    ],
    'Simple IF stmt'
);

is_deeply(
    tokenize(
        'SELECT * FROM foo WHERE 1=1 AND /* IF $c */v=/* $v */3/* ELSE */g=4/* END */'
    ),
    [
        [SQL, 'SELECT * FROM foo WHERE 1=1 AND '],
        [IF, 'c'],
        [SQL, 'v='],
        [VARIABLE, 'v'],
        [ELSE],
        [SQL, 'g=4'],
        [END_],
    ],
    'IF-ELSE stmt'
);

done_testing;

