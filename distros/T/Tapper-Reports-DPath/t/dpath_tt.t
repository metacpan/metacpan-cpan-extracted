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
plan tests => 6;

# -------------------- path division --------------------

my $tt = new Tapper::Reports::DPath::TT;
my $result;
my $template;
my $path;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

# component paths look (and must be) absolute, but are always taken relative to comp_root
like($tt->render(file     => "t/helloworld.tt"),   qr/Hello, world!\s*/, "tt hello world file");
is(  $tt->render(template => "SOME_TEMPLATE"),       "SOME_TEMPLATE",      "tt stupid template");
like($tt->render(template => "foo [% 'bar' %] baz"), qr/foo bar baz\s*/,   "tt template with static content tags");
$template = q{
[% SET bar = 'hello affe zomtec' -%]
foo [% bar %] baz
};
$expected = q{
foo hello affe zomtec baz
};
is($tt->render(template => $template), $expected, "tt template with variables 1");

$template = q|
[% search =  '{ "suite.name" => "perfmon" }//tap/tests_planned' -%]
[% res = search.reportdata() -%]
Planned tests:
[% FOREACH r IN res -%]
  [% r %]
[% END -%]
|;
$expected = q|
Planned tests:
  4
  3
  4
  3
|;
is($tt->render(template => $template), $expected, "tt template with reportdata");


$template = q|
[% dpath =  '//tests_planned' -%]
[% data  = [ { tests_planned => 1}, { tests_planned => 2}, { tests_planned => 3}, { tests_planned => 4}] -%]
[% res   = dpath.dpath_match(data) -%]
Planned tests:
[% FOREACH r IN res -%]
  [% r %]
[% END -%]
|;
$expected = q|
Planned tests:
  1
  2
  3
  4
|;
is($tt->render(template => $template), $expected, "tt template with dpath");
