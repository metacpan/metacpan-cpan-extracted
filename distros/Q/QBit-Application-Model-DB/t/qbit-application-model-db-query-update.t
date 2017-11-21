#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 6;
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

my $query = $app->db->query()->update(
    table => $app->db->table2,
    data  => {t1_f2 => 17, ml_field => {en => 'test', ru => 'тест', de => 'testen'}},
    filter => ['AND', [['field1' => '=' => \5], ['field2' => '=' => \8]]]
);

my ($sql, @params) = $query->get_sql_with_data();

eq_or_diff(
    $sql,
    q{UPDATE
    "table2"
SET
    "ml_field_de" = 'testen',
    "ml_field_en" = 'test',
    "ml_field_ru" = 'тест',
    "t1_f2" = '17'
WHERE (
    "table2"."field1" = '5'
    AND "table2"."field2" = '8'
)}
);

my $verification_sql = q{/* SQL with functions */
UPDATE
    "table2"
SET
    "ml_field_de" = CONCAT('de: ', "table2"."ml_field_de"),
    "ml_field_en" = CONCAT('en: ', "table2"."ml_field_en"),
    "ml_field_ru" = CONCAT('ru: ', "table2"."ml_field_ru"),
    "t1_f2" = ("table2"."t1_f2" + '1')
WHERE (
    "table2"."field1" = '5'
    AND "table2"."field2" = '8'
)};

$query = $app->db->query(comment => 'SQL with functions')->update(
    table => $app->db->table2,
    data  => {
        t1_f2    => ['+' => ['t1_f2', \1]],
        ml_field => {
            en => {CONCAT => [\'en: ', 'ml_field']},
            ru => {CONCAT => [\'ru: ', 'ml_field']},
            de => {CONCAT => [\'de: ', 'ml_field']}
        }
    },
    filter => ['AND', [['field1' => '=' => \5], ['field2' => '=' => \8]]]
);

($sql, @params) = $query->get_sql_with_data();

eq_or_diff($sql, $verification_sql);

#all_langs not affected
$query->all_langs(TRUE);

($sql, @params) = $query->get_sql_with_data();

eq_or_diff($sql, $verification_sql);

#one value for all fields
$query = $app->db->query()->update(
    table => $app->db->table2,
    data  => {
        t1_f2 => ['+' => ['t1_f2', \1]],
        #don't use fields with i18n attributes
        ml_field => ['*' => ['field1', 'field2']],
    },
    filter => ['AND', [['field1' => '=' => \5], ['field2' => '=' => \8]]]
);

($sql, @params) = $query->get_sql_with_data();

eq_or_diff(
    $sql,
    q{UPDATE
    "table2"
SET
    "ml_field_de" = ("table2"."field1" * "table2"."field2"),
    "ml_field_en" = ("table2"."field1" * "table2"."field2"),
    "ml_field_ru" = ("table2"."field1" * "table2"."field2"),
    "t1_f2" = ("table2"."t1_f2" + '1')
WHERE (
    "table2"."field1" = '5'
    AND "table2"."field2" = '8'
)}
);

#you can turn off a check for fields and use their with locale postfix
$query = $app->db->query(without_check_fields => TRUE)->update(
    table  => $app->db->table2,
    data   => {ml_field_de => {'ml_field_en' => ''},},
    filter => ['AND', [['field1' => '=' => \5], ['field2' => '=' => \8]]]
);

local $query->{'without_check_fields'} = {};

($sql, @params) = $query->get_sql_with_data();

eq_or_diff(
    $sql,
    q{UPDATE
    "table2"
SET
    "ml_field_de" = "table2"."ml_field_en"
WHERE (
    "table2"."field1" = '5'
    AND "table2"."field2" = '8'
)}
);

### join

$query = $app->db->query()->update(
    table => $app->db->table2,
    alias => 't2',
    data  => {
        t1_f2    => ['+' => ['t1_f2', \1]],
        ml_field => {
            en => {CONCAT => [\'en: ', 'ml_field']},
            ru => {CONCAT => [\'ru: ', 'ml_field']},
            de => {CONCAT => [\'de: ', 'ml_field']}
        }
    },
    filter => ['AND', [['field1' => '=' => \5], ['field2' => '=' => \8]]]
);

$query->join(
    table   => $app->db->table1,
    join_on => ['field2' => '=' => {'t1_f2' => => $app->db->table2}],
    filter  => ['OR', [['field5' => 'LIKE' => \'string'], ['field6' => '=' => \34]]]
);

($sql, @params) = $query->get_sql_with_data();

eq_or_diff(
    $sql,
    q{UPDATE
    "table2" AS "t2"
INNER JOIN "table1" ON (
    "table1"."field2" = "t2"."t1_f2"
)
SET
    "ml_field_de" = CONCAT('de: ', "t2"."ml_field_de"),
    "ml_field_en" = CONCAT('en: ', "t2"."ml_field_en"),
    "ml_field_ru" = CONCAT('ru: ', "t2"."ml_field_ru"),
    "t1_f2" = ("t2"."t1_f2" + '1')
WHERE (
    "t2"."field1" = '5'
    AND "t2"."field2" = '8'
)
AND (
    "table1"."field5" LIKE 'string'
    OR "table1"."field6" = '34'
)}
);
