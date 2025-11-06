use Test2::V0;
use Test::Alien;
use Neo4j::Client;

BEGIN {
  skip_all 'FFI::Platypus not installed'
    unless eval { require FFI::Platypus; 1 };
}

alien_ok 'Neo4j::Client';
ffi_ok { symbols => ['neo4j_log_level_str'] }, with_subtest {
  my($ffi) = @_;

  my $neo4j_log_level_str = $ffi->function( neo4j_log_level_str => ['int'] => 'string' );
  is $neo4j_log_level_str->call(3), 'DEBUG';
};
  
done_testing;
