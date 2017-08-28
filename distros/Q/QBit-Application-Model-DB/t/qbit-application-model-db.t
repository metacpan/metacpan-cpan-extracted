#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 26;
use Test::Differences;

use TestAppDB;

my $app = TestAppDB->new();

$app->pre_run();

$app->set_option(
    locales => {
        ru => {name => 'Russian', code => 'ru_RU', default => 1},
        en => {name => 'English', code => 'en_GB'},
        de => {name => 'German',  code => 'de_DE'}
    }
);

$app->set_app_locale('ru');

$app->db->_connect;

{
    my $filter = $app->db->filter({id => 5});

    is_deeply($filter->expression(), [AND => [[id => '=' => \5]]], 'Simple filter is correct');

    my $empty_filter = $app->db->filter();
    $filter->and($empty_filter);

    is_deeply($filter->expression(), [AND => [[id => '=' => \5]]],
        'Simple filter is correct after adding empty filter');
}

is_deeply(
    $app->db->filter({a => 1, b => [2, 3]})->expression(),
    [AND => [[a => '=' => \1], [b => '=' => \[2, 3]]]],
    'Check simple filter'
);

is_deeply(
    $app->db->filter()->and({a => 1, b => [2, 3]})->expression(),
    [AND => [[a => '=' => \1], [b => '=' => \[2, 3]]]],
    'Check simple filter (from empty)'
);

is_deeply(
    $app->db->filter([a => '>=' => \5])->expression(),
    [AND => [[a => '>=' => \5]]],
    'Check filter: cmp expression'
);

is_deeply(
    $app->db->filter()->and({a => 1})->and({b => [2, 3]})->expression(),
    [AND => [[a => '=' => \1], [b => '=' => \[2, 3]]]],
    'Check filter: and + and'
);

is_deeply(
    $app->db->filter()->and({a => 1})->and_not({b => [2, 3]})->expression(),
    [AND => [[a => '=' => \1], {NOT => [[AND => [[b => '=' => \[2, 3]]]]]}]],
    'Check filter: and + and not'
);

is_deeply(
    $app->db->filter()->and({a => 1})->or({b => [2, 3]})->expression(),
    [OR => [[AND => [[a => '=' => \1]]], [AND => [[b => '=' => \[2, 3]]]]]],
    'Check filter: and + or'
);

{
    my $filter = $app->db->filter({a => 1});

    my $second_filter = $app->db->filter({b => 2});
    $second_filter->or({c => 3});

    $filter->and($second_filter);

    is_deeply(
        $filter->expression(),
        ['AND', [['a', '=', \1], ['OR', [['AND', [['b', '=', \2]]], ['AND', [['c', '=', \3]]]]]]],
        'Check filter: A = 1 and (B = 2 or C = 3)'
    );
}

is_deeply(
    $app->db->filter()->and({a => 1})->or_not({b => [2, 3]})->expression(),
    [OR => [[AND => [[a => '=' => \1]]], {NOT => [[AND => [[b => '=' => \[2, 3]]]]]}]],
    'Check filter: and + or not'
);

my $query = $app->db->query->select(
    table  => $app->db->qtable1,
    alias  => 't1',
    fields => {
        id        => '',
        new_name  => 'field',
        undefined => \undef,
        val5      => \5,
        t1value   => {value => $app->db->qtable1},
        ml_field  => '',
        ml_field2 => 'ml_field',
        ml_field3 => {ml_field => 't1'},
        ml_func   => {CONCAT => ['ml_field', \'str', {TRIM => ['ml_field']}]},
        ml_func2 => {CONCAT => [\'str', {TRIM => ['ml_field']}]},
        expr     => ['/' => ['field',    {id => 't1'}, ['*' => ['value',    \5]]]],
        ml_expr  => ['/' => ['ml_field', {id => 't1'}, ['*' => ['value',    \5]]]],
        ml_expr2 => ['/' => ['field',    {id => 't1'}, ['*' => ['ml_field', \5]]]],
        cmp1    => [field    => '='  => \7],
        cmp2    => [field    => '='  => \undef],
        cmp3    => [field    => '<>' => \7],
        cmp4    => [field    => '='  => \[1, 2, 3, 4]],
        ml_cmp1 => [ml_field => '='  => \5],
    },
    filter => [
        AND => [
            [id => '>'  => \7],
            [id => '<>' => \[10, 12, 13]],
            [
                value => '= ANY' => $app->db->query->select(
                    table  => $app->db->table1,
                    fields => ['field2'],
                    filter => {field1 => 10, field2 => 20}
                )
            ],
        ]
    ]
  )->left_join(
    table  => $app->db->qtable2,
    alias  => 'qt2',
    fields => {q2value => 'field'},
    filter => [field => '>=' => \10]
  )->calc_rows(TRUE)->group_by(qw(id expr ml_field))->order_by('id', ['cmp1'], ['cmp2', TRUE])->limit(10, 20);

my ($sql, @data) = $query->get_sql_with_data();

eq_or_diff(
    $sql,
    q{SELECT
    "t1"."field" = '7' AS "cmp1",
    "t1"."field" IS NULL AS "cmp2",
    "t1"."field" <> '7' AS "cmp3",
    "t1"."field" IN ('1', '2', '3', '4') AS "cmp4",
    ("t1"."field" / "t1"."id" / ("t1"."value" * '5')) AS "expr",
    "t1"."id" AS "id",
    "t1"."ml_field_ru" = '5' AS "ml_cmp1",
    ("t1"."ml_field_ru" / "t1"."id" / ("t1"."value" * '5')) AS "ml_expr",
    ("t1"."field" / "t1"."id" / ("t1"."ml_field_ru" * '5')) AS "ml_expr2",
    "t1"."ml_field_ru" AS "ml_field",
    "t1"."ml_field_ru" AS "ml_field2",
    "t1"."ml_field_ru" AS "ml_field3",
    CONCAT("t1"."ml_field_ru", 'str', TRIM("t1"."ml_field_ru")) AS "ml_func",
    CONCAT('str', TRIM("t1"."ml_field_ru")) AS "ml_func2",
    "t1"."field" AS "new_name",
    "qt2"."field" AS "q2value",
    "t1"."value" AS "t1value",
    NULL AS "undefined",
    '5' AS "val5"
FROM "qtable1" AS "t1"
LEFT JOIN "qtable2" AS "qt2" ON (
    "qt2"."parent_id" = "t1"."id"
)
WHERE (
    "t1"."id" > '7'
    AND "t1"."id" NOT IN ('10', '12', '13')
    AND "t1"."value" = ANY (
        SELECT
            "table1"."field2" AS "field2"
        FROM "table1"
        WHERE (
            "table1"."field1" = '10'
            AND "table1"."field2" = '20'
        )
    )
)
AND (
    "qt2"."field" >= '10'
)
GROUP BY "id", "expr", "ml_field"
ORDER BY "id", "cmp1", "cmp2" DESC
LIMIT 10, 20},
    'Check query SQL'
);
is_deeply(\@data, [], 'Check query data');

($sql, @data) = $query->all_langs(TRUE)->get_sql_with_data();
eq_or_diff(
    $sql,
    q{SELECT
    "t1"."field" = '7' AS "cmp1",
    "t1"."field" IS NULL AS "cmp2",
    "t1"."field" <> '7' AS "cmp3",
    "t1"."field" IN ('1', '2', '3', '4') AS "cmp4",
    ("t1"."field" / "t1"."id" / ("t1"."value" * '5')) AS "expr",
    "t1"."id" AS "id",
    ("t1"."ml_field_de" = '5' OR "t1"."ml_field_en" = '5' OR "t1"."ml_field_ru" = '5') AS "ml_cmp1",
    ("t1"."ml_field_de" / "t1"."id" / ("t1"."value" * '5')) AS "ml_expr_de",
    ("t1"."ml_field_en" / "t1"."id" / ("t1"."value" * '5')) AS "ml_expr_en",
    ("t1"."ml_field_ru" / "t1"."id" / ("t1"."value" * '5')) AS "ml_expr_ru",
    ("t1"."field" / "t1"."id" / ("t1"."ml_field_de" * '5')) AS "ml_expr2_de",
    ("t1"."field" / "t1"."id" / ("t1"."ml_field_en" * '5')) AS "ml_expr2_en",
    ("t1"."field" / "t1"."id" / ("t1"."ml_field_ru" * '5')) AS "ml_expr2_ru",
    "t1"."ml_field_de" AS "ml_field_de",
    "t1"."ml_field_en" AS "ml_field_en",
    "t1"."ml_field_ru" AS "ml_field_ru",
    "t1"."ml_field_de" AS "ml_field2_de",
    "t1"."ml_field_en" AS "ml_field2_en",
    "t1"."ml_field_ru" AS "ml_field2_ru",
    "t1"."ml_field_de" AS "ml_field3_de",
    "t1"."ml_field_en" AS "ml_field3_en",
    "t1"."ml_field_ru" AS "ml_field3_ru",
    CONCAT("t1"."ml_field_de", 'str', TRIM("t1"."ml_field_de")) AS "ml_func_de",
    CONCAT("t1"."ml_field_en", 'str', TRIM("t1"."ml_field_en")) AS "ml_func_en",
    CONCAT("t1"."ml_field_ru", 'str', TRIM("t1"."ml_field_ru")) AS "ml_func_ru",
    CONCAT('str', TRIM("t1"."ml_field_de")) AS "ml_func2_de",
    CONCAT('str', TRIM("t1"."ml_field_en")) AS "ml_func2_en",
    CONCAT('str', TRIM("t1"."ml_field_ru")) AS "ml_func2_ru",
    "t1"."field" AS "new_name",
    "qt2"."field" AS "q2value",
    "t1"."value" AS "t1value",
    NULL AS "undefined",
    '5' AS "val5"
FROM "qtable1" AS "t1"
LEFT JOIN "qtable2" AS "qt2" ON (
    "qt2"."parent_id" = "t1"."id"
)
WHERE (
    "t1"."id" > '7'
    AND "t1"."id" NOT IN ('10', '12', '13')
    AND "t1"."value" = ANY (
        SELECT
            "table1"."field2" AS "field2"
        FROM "table1"
        WHERE (
            "table1"."field1" = '10'
            AND "table1"."field2" = '20'
        )
    )
)
AND (
    "qt2"."field" >= '10'
)
GROUP BY "id", "expr", "ml_field"
ORDER BY "id", "cmp1", "cmp2" DESC
LIMIT 10, 20},
    'Check all languages query SQL'
);
is_deeply(\@data, [], 'Check all languages query data');

is_deeply(
    [
        $app->db->query->select(
            table  => $app->db->qtable1,
            fields => [qw(id value)]
          )->get_sql_with_data()
    ],
    [
        $app->db->query->select(
            table  => $app->db->qtable1,
            fields => {id => '', value => ''}
          )->get_sql_with_data()
    ],
    'Check fields as array ref'
);

my $q =
  $app->db->query->select(table => $app->db->qtable1, fields => [qw(id value)])
  ->join(table => $app->db->qtable2, fields => ['field']);

($sql, @data) = $app->db->query->select(
    table  => $q,
    alias  => 't',
    fields => [qw(id value field)],
)->get_sql_with_data();
eq_or_diff(
    $sql,
    q{SELECT
    "t"."field" AS "field",
    "t"."id" AS "id",
    "t"."value" AS "value"
FROM (
    SELECT
        "qtable2"."field" AS "field",
        "qtable1"."id" AS "id",
        "qtable1"."value" AS "value"
    FROM "qtable1"
    INNER JOIN "qtable2" ON (
        "qtable2"."parent_id" = "qtable1"."id"
    )
) "t"},
    'Check select from subquery'
);

($sql, @data) = $app->db->query->select(table => $app->db->table1, fields => ['field1'])->join(
    table   => $q,
    alias   => 't',
    fields  => [qw(id value field)],
    join_on => ['id' => '=' => {field1 => $app->db->table1}]
)->get_sql_with_data();
eq_or_diff(
    $sql,
    q{SELECT
    "t"."field" AS "field",
    "table1"."field1" AS "field1",
    "t"."id" AS "id",
    "t"."value" AS "value"
FROM "table1"
INNER JOIN (
    SELECT
        "qtable2"."field" AS "field",
        "qtable1"."id" AS "id",
        "qtable1"."value" AS "value"
    FROM "qtable1"
    INNER JOIN "qtable2" ON (
        "qtable2"."parent_id" = "qtable1"."id"
    )
) "t" ON (
    "t"."id" = "table1"."field1"
)},
    'Check join with subquery'
);

($sql, @data) =
  $app->db->query->select(table => $app->db->qtable1, fields => [qw(id value)])
  ->union_all($app->db->query->select(table => $app->db->qtable2, fields => [qw(parent_id field)]))
  ->get_sql_with_data();
eq_or_diff(
    $sql,
    q{(
    SELECT
        "qtable1"."id" AS "id",
        "qtable1"."value" AS "value"
    FROM "qtable1"
)
UNION ALL
(
    SELECT
        "qtable2"."field" AS "field",
        "qtable2"."parent_id" AS "parent_id"
    FROM "qtable2"
)},
    'Check union'
);

is_deeply(
    $app->db->table1->_pkeys_or_filter_to_filter(1),
    $app->db->filter->or({field1 => 1}),
    'Check _pkeys_or_filter_to_filter: pk has 1 field, param scalar'
);

is_deeply(
    $app->db->table1->_pkeys_or_filter_to_filter([1, 2]),
    $app->db->filter->or({field1 => 1})->or({field1 => 2}),
    'Check _pkeys_or_filter_to_filter: pk has 1 field, param array of scalars'
);

is_deeply(
    $app->db->table2->_pkeys_or_filter_to_filter([10, '2000-01-01']),
    $app->db->filter->or({field1 => 10, field2 => '2000-01-01'}),
    'Check _pkeys_or_filter_to_filter: pk has 2 fields, param array'
);

is_deeply(
    $app->db->table2->_pkeys_or_filter_to_filter([[10, '2000-01-01'], [20, '2000-01-01']]),
    $app->db->filter->or({field1 => 10, field2 => '2000-01-01'})->or({field1 => 20, field2 => '2000-01-01'}),
    'Check _pkeys_or_filter_to_filter: pk has 2 fields, param array of arrays'
);

is_deeply(
    $app->db->table2->_pkeys_or_filter_to_filter({field1 => 10, field2 => '2000-01-01'}),
    $app->db->filter->or({field1 => 10, field2 => '2000-01-01'}),
    'Check _pkeys_or_filter_to_filter: pk has 2 fields, param hash'
);

is_deeply(
    $app->db->table2->_pkeys_or_filter_to_filter(
        [{field1 => 10, field2 => '2000-01-01'}, {field1 => 20, field2 => '2000-01-01'}]
    ),
    $app->db->filter->or({field1 => 10, field2 => '2000-01-01'})->or({field1 => 20, field2 => '2000-01-01'}),
    'Check _pkeys_or_filter_to_filter: pk has 2 fields, param array of hashes'
);

eval {$app->db->table1->get_all(fields => ['field1'], filter => {field2 => '2014-05-20'}, group_by => ['field2'],);};
is(
    ref($@) ? $@->message() : $@,
    gettext("You've forgotten grouping function for query field(s) '%s'.", 'field1'),
    'Grouping query with simple field dies.'
  );

eval {
    $app->db->table1->get_all(
        fields   => {'field1' => ''},
        filter   => {field2   => '2014-05-20'},
        group_by => ['field2'],
    );
};
is(
    ref($@) ? $@->message() : $@,
    gettext("You've forgotten grouping function for query field(s) '%s'.", 'field1'),
    'Grouping query with simple field dies.'
  );

$app->post_run();
