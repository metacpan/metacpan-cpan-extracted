use Test::More skip_all => '';
use Test::Exception;
use Module::Build;
use lib 'lib';
use lib '../lib';
use lib 't/lib';
use REST::Neo4p;
use Neo4p::Connect;
use Neo4p::TestAgent;

use strict;
use warnings;
no warnings qw(once);

my $build;
my ($user,$pass) = @ENV{qw/REST_NEO4P_TEST_USER REST_NEO4P_TEST_PASS/};
eval {
    $build = Module::Build->current;
    $user = $build->notes('user');
    $pass = $build->notes('pass');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : $ENV{REST_NEO4P_TEST_SERVER} // 'http://127.0.0.1:7474';
my $num_live_tests = 2;

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  skip 'Mojo::Exception not available', $num_live_tests unless eval "require Mojo::Exception; 1";
  my $q = REST::Neo4p::Query->new('match (a) return count(a)');
  dies_ok { $q->execute };
  like $@, qr/Try this on for size/;
  1;

}

done_testing;
