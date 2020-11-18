#-*-perl-*-
#$Id$
use Test::More;
use Test::Exception;
use Module::Build;
use lib 'lib';
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
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
my $num_live_tests = 1;

use_ok('REST::Neo4p');

my $agent1 = REST::Neo4p->agent;

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
    skip 'no connection to neo4j',$num_live_tests if $not_connected;
    pass 'Connected';
    REST::Neo4p->agent->timeout(0.1);
    my $agent2 = REST::Neo4p->agent;
    throws_ok {
      REST::Neo4p->connect('http://www.zzyxx.foo:7474');
    } 'REST::Neo4p::CommException';
    # if ( my $e = REST::Neo4p::CommException->caught() ) {
    # 	#      like $e->message, qr/Not Found|timeout|Bad hostname|Can't connect|Internal Exception/, 'timed out ok';
    # 	pass 'timed out ok';
    # }
    is $agent1, $agent2, 'same agent';

  }
done_testing;

