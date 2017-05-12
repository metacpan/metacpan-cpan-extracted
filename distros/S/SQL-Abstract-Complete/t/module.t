use strict;
use warnings;

use Test::Most;

use constant MODULE => 'SQL::Abstract::Complete';

BEGIN { use_ok(MODULE); }
require_ok(MODULE);

my %sacs;
ok( $sacs{'A'} = MODULE->new(), MODULE . '->new() ...as A' );
ok(
    $sacs{'B'} = MODULE->new( 'part_join' => "\n" ),
    MODULE . q{->new( 'part_join' => "\n" ) ...as B},
);

is( ref( $sacs{$_} ), MODULE, 'ref($object) ...with ' . $_ )
    foreach ( keys %sacs );

my ( $sql, @bind );
my $sac = $sacs{'A'};

foreach (
    [ 'A', 'SELECT * FROM table_name'  ],
    [ 'B', "SELECT *\nFROM table_name" ],
) {
    ( $sql, @bind ) = $sacs{ $_->[0] }->select('table_name');
    is(
        $sql, $_->[1],
        'Single simple table ...with ' . $_->[0],
    );
}

foreach (
    [ 'A', 'SELECT column_a, column_b, column_c FROM table_name'  ],
    [ 'B', "SELECT column_a, column_b, column_c\nFROM table_name" ],
) {
    ( $sql, @bind ) = $sacs{ $_->[0] }->select(
        'table_name',
        [ qw( column_a column_b column_c ) ],
    );
    is(
        $sql, $_->[1],
        'Single simple table and columns ...with ' . $_->[0],
    );
}

is(
    $sac->select('alpha'), 'SELECT * FROM alpha',
    q{select('alpha')},
);

is(
    $sac->select( \q(FROM alpha AS a) ), 'SELECT * FROM alpha AS a',
    q{select( \q(FROM alpha AS a) )},
);

is(
    $sac->select( ['alpha'] ), 'SELECT * FROM alpha',
    q{select( ['alpha'] )},
);

is(
    $sac->select( [ \q(FROM alpha AS a) ] ), 'SELECT * FROM alpha AS a',
    q{select( [ \q(FROM alpha AS a) ] )},
);

is(
    $sac->select(
        [
            [ [ qw( alpha a ) ]       ],
            [ [ qw( beta  b ) ], 'id' ],
        ],
    ), 'SELECT * FROM alpha AS a JOIN beta AS b USING(id)',
    q{select( [ [ [ qw( alpha a ) ] ], [ [ qw( beta  b ) ], 'id' ] ] )},
);

is(
    $sac->select(
        [
            [ [ qw( alpha a ) ]       ],
            [ { 'beta' => 'b' }, 'id' ],
        ],
    ), 'SELECT * FROM alpha AS a JOIN beta AS b USING(id)',
    q{select( [ [ [ qw( alpha a ) ] ], [ { 'beta' => 'b' }, 'id' ] ] )},
);

is(
    $sac->select(
        [
            [ [ qw( alpha a ) ] ],
            [ { 'beta' => 'b' }, 'id' ],
            \q{ LEFT JOIN something AS s USING(whatever) },
            [ \q{ LEFT JOIN }, { 'omega' => 'o' }, 'last_id' ],
            [ \q{ LEFT JOIN }, { 'stuff' => 't' }, \q{ ON t.thing_id = b.thing_id } ],
            [
                [ qw( pi p ) ],
                {
                    'join'  => 'left',
                    'using' => 'number_id',
                },
            ],
        ],
    ), q{SELECT * FROM alpha AS a JOIN beta AS b USING(id) LEFT JOIN something AS s USING(whatever) } .
       q{LEFT JOIN omega AS o USING(last_id) LEFT JOIN stuff AS t ON t.thing_id = b.thing_id } .
       q{LEFT JOIN pi AS p USING(number_id)},
    'Full select() table functionality',
);

is(
    $sac->select(
        'table',
        [ qw( one two three ) ],
    ), 'SELECT one, two, three FROM table',
    q{select( 'table', [ qw( one two three ) ] )},
);

is(
    $sac->select(
        'table',
        [
            'one',
            \q{ IF( two > 10, 1, 0 ) AS two_bool },
            { 'three' => 'col_three' },
        ],
    ), 'SELECT one, IF( two > 10, 1, 0 ) AS two_bool, three AS col_three FROM table',
    'Full select() fields functionality',
);

is(
    $sac->select(
        'table',
        ['one'],
        undef,
        {
            'group_by' => 'two',
            'having'   => [ { 'MAX(three)' => { '>' => 9 } } ],
            'order_by' => [ 'one', { '-desc' => 'four' }, 'five' ],
            'rows'     => 5,
            'page'     => 3,
        },
    ), q{SELECT one FROM table GROUP BY two HAVING ( MAX(three) > ? ) } .
       q{ORDER BY one, four DESC, five LIMIT 5 OFFSET 10},
    'Full select() \%other functionality',
);

is( $sac->_sqlcase('from'), 'FROM', q{$sac->_sqlcase('from')} );
is( $sac->_sqlcase(undef), '', '$sac->_sqlcase(undef)' );

( $sql, @bind ) = $sac->select(
    'table',
    ['one'],
    undef,
    {   'group_by' => 'two',
        'having'   => [ { 'MAX(three)' => { '>' => 9 } } ],
        'order_by' => [ 'one', { '-desc' => 'four' }, 'five' ],
        'rows'     => 5,
        'page'     => 3,
    },
);
is( $sql,
    q{SELECT one FROM table GROUP BY two HAVING ( MAX(three) > ? ) }
        . q{ORDER BY one, four DESC, five LIMIT 5 OFFSET 10},
    'Full select() \%other functionality',
);
is( @bind, 1, 'Bind param returned' );

done_testing;
