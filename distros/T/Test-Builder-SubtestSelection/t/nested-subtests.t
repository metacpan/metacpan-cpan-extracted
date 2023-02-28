#<<<
use strict; use warnings;
#>>>

BEGIN {
  @ARGV = qw( -s 1 );
}

use Test::Builder::SubtestSelection;
use Test::Builder::Tester tests => 1;
use Test::More import => [ qw( pass plan subtest ) ];

test_out( '# Subtest: first' );
test_out( '    1..2' );
test_out( '    ok 1 - first 1' );
test_out( '    # Subtest: second' );
test_out( '        1..2' );
test_out( '        ok 1 - second 1' );
test_out( '        ok 2 - second 2' );
test_out( '    ok 2 - second' );
test_out( 'ok 1 - first' );
test_out( 'ok 2 # skip forced by Test::Builder::SubtestSelection' );

subtest 'first' => sub {
  plan tests => 2;
  pass( 'first 1' );
  subtest 'second' => sub {
    plan tests => 2;
    pass( 'second 1' );
    pass( 'second 2' );
  };
};

subtest 'third' => sub {
  plan tests => 2;
  pass( 'third 1' );
  pass( 'third 2' );
};

test_test( 'first subtest selected by number' );
