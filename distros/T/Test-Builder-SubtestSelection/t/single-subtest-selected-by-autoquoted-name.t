#<<<
use strict; use warnings;
#>>>

BEGIN {
  @ARGV = ( '-s', '[a   :previous' );
}

use Test::Builder::SubtestSelection;
use Test::Builder::Tester tests => 1;
use Test::More import => [ qw( pass plan subtest ) ];

test_out( '# Subtest: [a   :previous' );
test_out( '    1..2' );
test_out( '    ok 1 - [a' );
test_out( '    ok 2 - :previous' );
test_out( 'ok 1 - [a   :previous' );
test_out( 'ok 2 # skip forced by Test::Builder::SubtestSelection' );

subtest '[a   :previous' => sub {
  plan tests => 2;
  pass( '[a' );
  pass( ':previous' );
};

subtest 'second' => sub {
  plan tests => 2;
  pass( 'second 1' );
  pass( 'second 2' );
};

test_test( 'first subtest selected by name' );
