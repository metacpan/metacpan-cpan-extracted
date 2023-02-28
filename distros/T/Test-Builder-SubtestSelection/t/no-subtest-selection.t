#<<<
use strict; use warnings;
#>>>

use Test::Builder::SubtestSelection;
use Test::Builder::Tester tests => 1;
use Test::More import => [ qw( pass plan subtest ) ];

test_out( '# Subtest: first' );
test_out( '    1..2' );
test_out( '    ok 1 - first 1' );
test_out( '    ok 2 - first 2' );
test_out( 'ok 1 - first' );
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

test_test( 'no subtest selection' );
