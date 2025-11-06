use lib '../lib';
use Test2::V0;
use Test::Alien;
use Neo4j::Client;

alien_ok 'Neo4j::Client';
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($mod) = @_;
  ok $mod->version;
  is $mod->version, Neo4j::Client->version;
  diag 'libneo4j-omni ' . $mod->version;

  is $mod->neo4j_log_level_str(2), 'INFO';
};

diag(Neo4j::Client->cflags);
diag(Neo4j::Client->libs);
  
done_testing;

__DATA__
 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <neo4j-client.h>
#include "values.h"

const char *version(const char *class)
{
    neo4j_value_t I = neo4j_identity(-1);
    return NEO4J_VERSION;
}
 
MODULE = TA_MODULE PACKAGE = TA_MODULE
 
const char *version(class);
    const char *class;

char *
neo4j_log_level_str(class, U8 level)
  C_ARGS: level
