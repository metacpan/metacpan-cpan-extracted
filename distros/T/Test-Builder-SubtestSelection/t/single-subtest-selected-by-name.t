#<<<
use strict; use warnings;
#>>>

BEGIN {
  @ARGV = ( '--subtest', 'fi..t' ); # matching 'first'
}

use Test::Builder::SubtestSelection;
use Test::Builder::Tester tests => 1;
use Test::More import => [ qw( pass plan subtest ) ];

test_out( '# Subtest: first' );
test_out( '    1..2' );
test_out( '    ok 1 - first 1' );
test_out( '    ok 2 - first 2' );
test_out( 'ok 1 - first' );
test_out( 'ok 2 # skip forced by Test::Builder::SubtestSelection' );

subtest 'first' => sub {
  plan tests => 2;
  pass( 'first 1' );
  pass( 'first 2' );
};

subtest 'second' => sub {
  plan tests => 2;
  pass( 'second 1' );
  pass( 'second 2' );
};

test_test( 'first subtest selected by name' );
