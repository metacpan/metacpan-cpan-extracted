#! perl

use Test::More;

BEGIN {
        use Class::C3;
        use MRO::Compat;
}

use Tapper::Reports::DPath::TT 'render';
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Data::Dumper;

print "TAP Version 13\n";
plan tests => 3;

# -------------------- path division --------------------

my $tt = new Tapper::Reports::DPath::TT;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $template = q|
[% data  = [ { tests_planned => 1}, { tests_planned => 2}, { tests_planned => 3}, { tests_planned => 4}] -%]
[% data.Dumper -%]
|;
my $expected = q|
$VAR1 = [
          {
            'tests_planned' => 1
          },
          {
            'tests_planned' => 2
          },
          {
            'tests_planned' => 3
          },
          {
            'tests_planned' => 4
          }
        ];
|;
is($tt->render(template => $template), $expected, "tt template with Dumper");


$template = q|
[% data  = [ { tests_planned => 1}, { tests_planned => 2}, { tests_planned => 3}, { tests_planned => 4}] -%]
[% data.to_yaml -%]
|;
$expected = q|
---
- tests_planned: 1
- tests_planned: 2
- tests_planned: 3
- tests_planned: 4
|;
is($tt->render(template => $template), $expected, "tt template with YAML");

$template = q|
[% data  = [ { tests_planned => 1}, { tests_planned => 2}, { tests_planned => 3}, { tests_planned => 4}] -%]
[% data.to_json -%]
|;
$expected = q|
[
   {
      "tests_planned" : 1
   },
   {
      "tests_planned" : 2
   },
   {
      "tests_planned" : 3
   },
   {
      "tests_planned" : 4
   }
]|;
my $render = $tt->render(template => $template);
chomp $render; # we get an additional newline on some systems, don't know why
is($render, $expected, "tt template with JSON");
