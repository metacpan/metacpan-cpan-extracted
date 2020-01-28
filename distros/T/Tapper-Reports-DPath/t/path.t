#! perl

use Test::More 0.88;

BEGIN {
        use Class::C3;
        use MRO::Compat;
}
use Tapper::Reports::DPath;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Data::Dumper;

# -------------------- path division --------------------

my $dpath = new Tapper::Reports::DPath;
my $condition;
my $path;
my @res;

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{ suite_name => "TestSuite-LmBench" } :: /tap/section/math/*/bogomips[0]');
is($condition, '{ suite_name => "TestSuite-LmBench" }', "condition easy");
is($attrs,     undef,                                   "path easy");
is($path,      '/tap/section/math/*/bogomips[0]',       "path easy");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{ suite_name => "TestSuite::LmBench" } :: /tap/section/math/*/bogomips[0]');
is($condition, '{ suite_name => "TestSuite::LmBench" }', "condition colons");
is($attrs,     undef,                                    "path easy");
is($path,      '/tap/section/math/*/bogomips[0]',        "path colons");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{ suite_name => "{TestSuite::LmBench}" } :: /tap/section/math/*/bogomips[0]');
is($condition, '{ suite_name => "{TestSuite::LmBench}" }', "condition balanced braces");
is($attrs,     undef,                                      "path easy");
is($path,      '/tap/section/math/*/bogomips[0]',          "path balanced braces");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{ suite_name => "TestSuite::LmBench}" } :: /tap/section/math/*/bogomips[0]');
is($condition, '{ suite_name => "TestSuite::LmBench}" }', "condition unbalanced braces");
is($attrs,     undef,                                     "path easy");
is($path,      '/tap/section/math/*/bogomips[0]',         "path unbalanced braces");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{ } :: /tap/section/math/*/bogomips[0]');
is($condition, '{ }',                                     "condition empty braces");
is($attrs,     undef,                                     "path easy");
is($path,      '/tap/section/math/*/bogomips[0]',         "path unbalanced braces");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path(':: /tap/section/math/*/bogomips[0]');
is($condition, undef,                                     "condition just colons");
is($attrs,     undef,                                     "path easy");
is($path,      '/tap/section/math/*/bogomips[0]',         "path unbalanced braces");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('/tap/section/math/*/bogomips[0]');
is($condition, undef,                                     "condition no braces no colons");
is($attrs,     undef,                                     "path easy");
is($path,      '/tap/section/math/*/bogomips[0]',         "path unbalanced braces");

# ----- triplet syntax - condition :: attr :: path -----

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{ } :: {BBB} :: /tap/section/math/*/bogomips[0]');
is($condition, '{ }',                                     "cond::attr::path 1 - condition");
is($attrs,     '{BBB}',                                   "cond::attr::path 1 - attributes");
is($path,      '/tap/section/math/*/bogomips[0]',         "cond::attr::path 1 - path");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{AAA} :: { } :: /tap/section/math/*/bogomips[0]');
is($condition, '{AAA}',                                   "cond::attr::path 2 - condition");
is($attrs,     '{ }',                                     "cond::attr::path 2 - attributes");
is($path,      '/tap/section/math/*/bogomips[0]',         "cond::attr::path 2 - path");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path('{ } :: /tap/section/math/*/bogomips[0]');
is($condition, '{ }',                                     "cond::attr::path 3 - condition");
is($attrs,     undef,                                     "cond::attr::path 3 - attributes");
is($path,      '/tap/section/math/*/bogomips[0]',         "cond::attr::path 3 - path");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path(' :: /tap/section/math/*/bogomips[0]');
is($condition, undef,                                     "cond::attr::path 4 - condition");
is($attrs,     undef,                                     "cond::attr::path 4 - attributes");
is($path,      '/tap/section/math/*/bogomips[0]',         "cond::attr::path 4 - path");

($condition, $attrs, $path) = Tapper::Reports::DPath::_extract_condition_attrs_and_path(' { hot => "stuff" } :: { "even" => 2 } :: /tap/section/math/*/bogomips[0]');
is($condition, '{ hot => "stuff" }',                      "cond::attr::path 5 - condition");
is($attrs,     '{ "even" => 2 }',                         "cond::attr::path 5 - attributes");
is($path,      '/tap/section/math/*/bogomips[0]',         "cond::attr::path 5 - path");

done_testing;
