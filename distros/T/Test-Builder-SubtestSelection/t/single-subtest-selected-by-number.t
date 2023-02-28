#<<<
use strict; use warnings;
#>>>

BEGIN {
  @ARGV = qw( -s 2 );
}

use Test::Builder::SubtestSelection;
use Test::Builder::Tester tests => 1;
use Test::More import => [ qw( pass plan subtest ) ];

test_out( 'ok 1 # skip forced by Test::Builder::SubtestSelection' );
test_out( '# Subtest: second' );
test_out( '    1..2' );
test_out( '    ok 1 - second 1' );
test_out( '    ok 2 - second 2' );
test_out( 'ok 2 - second' );

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

test_test( 'second subtest selected by number' );
