#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 1;
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

my $query = $app->db->query->select(
    table  => $app->db->qtable1,
    fields => {
        field => '',
        cnt   => {COUNT => ['id']},
    },
    filter => [id => '>' => \10]
)->group_by(qw(field))->having(['cnt' => '>=' => \100])->order_by('field')->limit(10, 20);

my ($sql, @data) = $query->get_sql_with_data();

eq_or_diff(
    $sql,
    q{SELECT
    COUNT("qtable1"."id") AS "cnt",
    "qtable1"."field" AS "field"
FROM "qtable1"
WHERE (
    "qtable1"."id" > '10'
)
GROUP BY "field"
HAVING "cnt" >= '100'
ORDER BY "field"
LIMIT 10, 20},
    'Check query SQL with having'
);

$app->post_run();
