#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 1;
use Test::Differences;

use TestAppDB;

my $app = TestAppDB->new();

$app->pre_run();

$app->set_option(locales => {ru => {name => 'Russian', code => 'ru_RU', default => 1},});

$app->set_app_locale('ru');

$app->db->_connect;

my $first_query = $app->db->query(comment => 'first query')->select(
    table  => $app->db->qtable1,
    alias  => 'f',
    fields => [qw(id field)],
);

my $second_query = $app->db->query(comment => 'second query')->select(
    table  => $first_query,
    alias  => 's',
    fields => {
        id  => '',
        cnt => {SUM => ['field']},
    },
    filter => [id => '>' => \10]
)->group_by(qw(id))->limit(10, 20);

my ($sql, @data) = $second_query->get_sql_with_data();

eq_or_diff(
    $sql,
    q{/* second query */
SELECT
    SUM("s"."field") AS "cnt",
    "s"."id" AS "id"
FROM (
    /* first query */
    SELECT
        "f"."field" AS "field",
        "f"."id" AS "id"
    FROM "qtable1" AS "f"
) "s"
WHERE (
    "s"."id" > '10'
)
GROUP BY "id"
LIMIT 10, 20},
    'Check comments'
);

$app->post_run();
