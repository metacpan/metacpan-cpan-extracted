#!perl -T

use Test::More tests => 1;
use Parallel::MPM::Prefork;

my ($data, $exit_code);

ok( pf_init(), 'Initialization' )
  or diag($Parallel::MPM::Prefork::error);

pf_done();
