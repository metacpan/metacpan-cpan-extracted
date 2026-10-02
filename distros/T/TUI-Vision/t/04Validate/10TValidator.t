use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Validate::Validator';
}

#--------------
note 'exports';
#--------------

ok( defined &TValidator,     'TValidator is exported' );
ok( defined &new_TValidator, 'new_TValidator is exported' );

is( TValidator, TValidator, 'TValidator returns package name' );
is( TValidator->name, 'TValidator', 'name() is correct' );

#------------------
note 'constructor';
#------------------

my $v = TValidator->new();
isa_ok( $v, TValidator, 'object created via new()' );

my $v2 = new_TValidator();
isa_ok( $v2, TValidator, 'object created via new_TValidator()' );

#-----------------
note 'attributes';
#-----------------

can_ok( $v, 'status' );
can_ok( $v, 'options' );

is( $v->status,  0, 'status default is 0' );
is( $v->options, 0, 'options default is 0' );

#--------------
note 'methods';
#--------------

can_ok(
  $v, qw(
    error
    isValidInput
    isValid
    transfer
    validate
  )
);

ok( $v->isValidInput( 'abc', 0 ), 'isValidInput() returns true' );
ok( $v->isValid( 'abc' ),         'isValid() returns true' );
ok( $v->validate( 'abc' ),        'validate() returns true' );

is( $v->transfer( 'abc', undef, 0 ), 0, 'transfer() returns 0' );

done_testing();
