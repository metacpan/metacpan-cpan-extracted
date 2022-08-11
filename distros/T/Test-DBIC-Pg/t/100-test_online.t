#! perl -I. -w
use t::Test::abeltje;

use DBI;
use Test::DBIC::Pg;

plan skip_all => "set TEST_ONLINE to enable this test" unless $ENV{TEST_ONLINE};

my $dummy = Test::DBIC::Pg->new(schema_class => 'DummySchema');
my $p = DBI->connect(sprintf("dbi:Pg:db=%s", $dummy->TMPL_DB));

if (! $p) {
    BAIL_OUT("Cannot connect, please set PGHOST and friends!");
}

pass("Connection to Pg");
abeltje_done_testing();
