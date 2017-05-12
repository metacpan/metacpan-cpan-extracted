use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use warnings;
use strict;

use Test::More tests => 4;

use Tapper::Cmd::Host;
use Tapper::Model 'model';
use Test::Exception;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $cmd = Tapper::Cmd::Host->new();
isa_ok($cmd, 'Tapper::Cmd::Host');


#######################################################
#
#   check add method
#
#######################################################
throws_ok {$cmd->add({
                      name => 'bullock',
                      comment => 'no comment',
                      free => 1,
                      active => 1,
                      is_deleted => 0,
                      pool_free => 1,
                      pool_count => 2,
                     }
                    )
   } qr/pool_count can not go together with pool_free/, 'Throws error for pool_count together with pool_free'; # There must not be a comma between block and test in throws_ok

my $id = $cmd->add({
                    name => 'bullock',
                    comment => 'no comment',
                    free => 1,
                    active => 1,
                    is_deleted => 0,
                    pool_free => 1,
                   }
                  );
my $host = model('TestrunDB')->resultset('Host')->find($id);
is($host->name, 'bullock', 'Host bullock added');
ok($host->is_pool, 'Bullock is pool host');
