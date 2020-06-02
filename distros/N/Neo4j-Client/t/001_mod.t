use Test::More;
use ExtUtils::CChecker;
use strict;

ok eval "use blib; 1", "Neo4j::Client made";
use_ok('Neo4j::Client');

my $cc = ExtUtils::CChecker->new;
my $tryc =<<'TRY';
#include<neo4j-client.h>
int main() {
int rc=neo4j_client_init();
printf( "%s\n", libneo4j_client_version());
}
TRY
$cc->push_extra_linker_flags(map { s{/lib/}{/arch/};$_ } Neo4j::Client::LIBS_ARY());
$cc->push_extra_compiler_flags(map { s{/lib/}{/arch/};$_ } Neo4j::Client::CCFLAGS_ARY());
ok $cc->try_compile_run( source => $tryc ), "Locations work and test pgm runs";


done_testing;
