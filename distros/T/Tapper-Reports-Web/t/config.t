#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Reports::Web;

plan tests => 1;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

is(Tapper::Reports::Web->config->{tapper_config}{test_value}, "test", "Tapper config correctly merged in");
