use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Validate::LookupValidator';
}

my $v;

subtest 'Object creation' => sub {
  lives_ok {
    $v = TUI::Validate::LookupValidator->new();
  } 'Object created';
  isa_ok( $v, TLookupValidator );
};

subtest 'isValid delegates to lookup' => sub {
  ok( $v->isValid( 'anything' ), 'isValid returns true (default lookup)' );
  ok( $v->isValid( '' ),         'isValid accepts empty string' );
};

subtest 'lookup default implementation' => sub {
  ok( $v->lookup( 'foo' ), 'lookup returns true' );
  ok( $v->lookup( '123' ), 'lookup returns true for numeric input' );
};

done_testing();
