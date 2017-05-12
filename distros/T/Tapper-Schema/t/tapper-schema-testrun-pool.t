
use strict;
use warnings;
use Test::More tests => 21;
use Tapper::Config;

use_ok('Tapper::Schema');

use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;

# --------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/pool_testrun.yml' );
# --------------------------------------------------------------------------------

sub model
{
        my ($schema_basename) = @_;

        $schema_basename ||= 'TestrunDB';

        my $schema_class = "Tapper::Schema::$schema_basename";

        # lazy load class
        eval "use $schema_class";
        if ($@) {
                print STDERR $@;
                return undef;
        }
        return $schema_class->connect(Tapper::Config->subconfig->{database}{$schema_basename}{dsn},
                                      Tapper::Config->subconfig->{database}{$schema_basename}{username},
                                      Tapper::Config->subconfig->{database}{$schema_basename}{password});
}

my $job = model->resultset('TestrunScheduling')->first;
isa_ok($job, 'Tapper::Schema::TestrunDB::Result::TestrunScheduling');

my $host = model->resultset('Host')->find({name => 'pool_iring'});
is($host->pool_elements->count, 1, 'Pool has already one element');


$job->host_id($host->id);
ok($job->host->is_pool, 'Host is pool host');

$job->mark_as_running;
is($job->host->pool_free, 1, 'One less host in pool');
ok($job->host->free, 'Nonempty pool still free');

is $host->pool_count, 3, 'pool count contains free and nonfree pool elements';

$job->mark_as_running;
is($job->host->pool_free, 0, 'One less host in pool');
is($job->host->free, 0, 'Empty pool no longer free');

$job->mark_as_finished;
is($job->host->pool_free, 1, 'Pool increased after free_host');
is($job->host->free, 1, 'Pool free again after free_host');

$host = model->resultset('Host')->find({name => 'iring'});
is($host->pool_master->name,'pool_iring', 'Associated pool master found');

# updating pools

$host = model->resultset('Host')->new({name => 'pool_update_test',
                                       free => 1,
                                       active => 1,
                                      })->insert;
is($host->pool_count, undef, 'No pool count on nonpool host');

$host->pool_count(2);
is($host->pool_count, 2, 'Pool count set for  nonpool host');

$host->pool_count(4);
is($host->pool_count, 4, 'Pool count updated for free pool host');

$job->host_id($host->id);
$job->mark_as_running;

# reload host from database
$host = model->resultset('Host')->find({name => 'pool_update_test'});
is($host->pool_free, 3, 'Free hosts reduced');
is($host->pool_count, 4, 'All pool in hosts count unchanged');

ok($host->free, 'Nonempty pool host is free');
$host->pool_count(1);
is($host->pool_free, 0, 'Free hosts reduced by reducing pool count');
is($host->pool_count, 1, 'Pool count reduced');
ok(not($host->free), 'Empty pool host is not free');
