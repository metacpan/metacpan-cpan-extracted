#! perl

use Test::More;

BEGIN {
        use Class::C3;
        use MRO::Compat;
}

use Tapper::Reports::DPath::Mason 'render';
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Data::Dumper;

print "TAP Version 13\n";
plan tests => 5;

# -------------------- path division --------------------

my $mason = new Tapper::Reports::DPath::Mason;
my $result;
my $template;
my $path;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

use Cwd 'abs_path', 'cwd';


# component paths look (and must be) absolute, but are always taken relative to comp_root
like($mason->render(file     => "/t/helloworld.mas"),   qr/Hello, world!\s*/, "mason hello world file");
is(  $mason->render(template => "SOME_TEMPLATE"),       "SOME_TEMPLATE",      "mason stupid template");
like($mason->render(template => "foo <% 'bar' %> baz"), qr/foo bar baz\s*/,   "mason template with static content tags");
$template = q{
% my $bar = 'hello affe zomtec';
foo <% $bar %> baz
};
$expected = q{
foo hello affe zomtec baz
};
is($mason->render(template => $template), $expected, "mason template with variables 1");

$template = q|
% my @res = reportdata '{ "suite.name" => "perfmon" }//tap/tests_planned';
Planned tests:
% foreach (@res) {
  <% $_ %>
% }
|;
$expected = q|
Planned tests:
  4
  3
  4
  3
|;
is($mason->render(template => $template), $expected, "mason template with dpath perfmon tests_planned");
