use strict;
use warnings;
use utf8;
use Test::More;

use SQL::TwoWay;

subtest 'No operation' => sub {
    match(
        'Positive Int',
        q{SELECT * FROM foo}, { },
        q{SELECT * FROM foo}, []
    );
};

subtest 'Simple replacement' => sub {
    match(
        'Positive Int',
        q{SELECT * FROM foo WHERE boo=/* $b */3}, { b => 4 },
        q{SELECT * FROM foo WHERE boo=?}, [4]
    );
    match(
        'Negative Int',
        q{SELECT * FROM foo WHERE boo=/* $b */-3}, { b => -4 },
        q{SELECT * FROM foo WHERE boo=?}, [-4]
    );
    match(
        'Positive Double',
        q{SELECT * FROM foo WHERE boo=/* $b */3.14}, { b => 1.41421356 },
        q{SELECT * FROM foo WHERE boo=?}, [1.41421356]
    );
    match(
        'String',
        q{SELECT * FROM foo WHERE boo=/* $b */"WoW"}, { b => "Gah!" },
        q{SELECT * FROM foo WHERE boo=?}, ['Gah!']
    );
    match(
        'Double quote string with escape',
        q{SELECT * FROM foo WHERE boo=/* $b */"W""o\"W"}, { b => "Gah!" },
        q{SELECT * FROM foo WHERE boo=?}, ['Gah!']
    );
    match(
        'Single quote string',
        q{SELECT * FROM foo WHERE boo=/* $b */'WoW'}, { b => "Gah!" },
        q{SELECT * FROM foo WHERE boo=?}, ['Gah!']
    );
    match(
        'Single quote string with escape',
        q{SELECT * FROM foo WHERE boo=/* $b */'W''o\'W'}, { b => "Gah!" },
        q{SELECT * FROM foo WHERE boo=?}, ['Gah!']
    );
    match(
        'String List',
        q{SELECT * FROM foo WHERE boo IN /* $b */("foo","bar")}, { b => ["Gah!", 'Bah!'] },
        q{SELECT * FROM foo WHERE boo IN (?,?)}, ['Gah!', 'Bah!']
    );
    match(
        'Numeric List',
        q{SELECT * FROM foo WHERE boo IN /* $b */(3 , 5)}, { b => [8,3,4] },
        q{SELECT * FROM foo WHERE boo IN (?,?,?)}, [8,3,4]
    );
};

subtest 'IF statement' => sub {
    match(
        'Simple, true',
        q{SELECT * FROM foo /* IF $cond */WHERE 1=1/* END */}, { cond => 1 },
        q{SELECT * FROM foo WHERE 1=1}, [],
    );
    match(
        'Simple, false',
        q{SELECT * FROM foo /* IF $cond */WHERE 1=1/* END */}, { cond => 0 },
        q{SELECT * FROM foo }, [],
    );
    match(
        'IF-ELSE, true',
        q{SELECT * FROM foo WHERE /* IF $cond */b=/* $b */5/* ELSE */c=/* $c */7/* END */}, { cond => 1, b => 3, c => 8 },
        q{SELECT * FROM foo WHERE b=?}, [3],
    );
    match(
        'IF-ELSE, false',
        q{SELECT * FROM foo WHERE /* IF $cond */b=/* $b */5/* ELSE */c=/* $c */7/* END */}, { cond => 0, b => 3, c => 8 },
        q{SELECT * FROM foo WHERE c=?}, [8],
    );
};

done_testing;

sub match {
    my ($name, $sql, $params, $expected_sql, $expected_binds) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    subtest $name => sub {
        local $Test::Builder::Level = $Test::Builder::Level + 6;
        my ($sql, @binds) = two_way_sql($sql, $params);
        is($sql, $expected_sql);
        is(0+@binds, 0+@$expected_binds);
        for (0..@$expected_binds-1) {
            is($binds[$_], $expected_binds->[$_]);
        }
    };
}
