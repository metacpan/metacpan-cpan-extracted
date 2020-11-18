#-*-perl-*-
#$Id$
use Test::More tests => 4;
use Test::Exception;
use Module::Build;
use lib qw|../lib lib|;
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
my $num_live_tests = 3;



use_ok('REST::Neo4p');

my $not_connected;
eval {
    REST::Neo4p->connect($TEST_SERVER,$user,$pass);
  };
if ( my $e = REST::Neo4p::CommException->caught() ) {
  if ($e->message =~ /certificate verify failed/i) {
    REST::Neo4p->agent->ssl_opts(verify_hostname => 0); # testing only!
    REST::Neo4p->connect($TEST_SERVER,$user,$pass);
  }
  else {
    $not_connected = 1;
  }
}
elsif ( $e = Exception::Class->caught()) {
  $not_connected = 1;
}

diag "No local connection to Neo4j; tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  my $AGENT = REST::Neo4p->agent;
  skip 'Agent is Neo4j::Driver', $num_live_tests if (ref($AGENT) =~ /Neo4j::Driver/);
  ok $AGENT->{_actions}{node} =~ s/:[0-9]+/:8474/, 'change post port to 8474 (should refuse connection)';
  $REST::Neo4p::AGENT::RETRY_WAIT=1; # speed it up for test
  throws_ok { $AGENT->get_node(1) } 'REST::Neo4p::CommException';
  like $@, qr/after 3 retries/, 'error message indicates retries attempted';

  CLEANUP : {
      1;
  }
}
#$Id$
