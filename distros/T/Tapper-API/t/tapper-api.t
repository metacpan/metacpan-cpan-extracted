use strict;
use warnings;

BEGIN{
        $ENV{TAPPER_CONFIG_FILE} = 't/tapper-api.cfg';
}
use Test::More tests => 3;
use Test::Mojo;

use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;

# --------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/simple_testrun.yml' );
# --------------------------------------------------------------------------------

my $t = Test::Mojo->new('Tapper::API');


####################################################################
#                                                                  #
#   Check whether routing works at all.                            #
#                                                                  #
####################################################################

$t->put_ok('/api/test/unit-test/test', {}, json => {"foo" => "bar"})->status_is(202)->json_is({"key" => "value"});
