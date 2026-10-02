use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Validate::FilterValidator';
  use_ok 'TUI::MsgBox::Const';
}

my $v;

subtest 'Object creation' => sub {
  lives_ok {
    $v = TUI::Validate::FilterValidator->new( validChars => 'A-Za-z0-9' );
  } 'Object created';
  isa_ok( $v, TFilterValidator );
};

subtest 'Alternate constructors' => sub {
  my $v;
  lives_ok { $v = new_TFilterValidator( 'a-z' ) } 'Object created';
  isa_ok( $v, TFilterValidator );
  is( $v->validChars, 'a-z', 'new_TFilterValidator() works' );
};

subtest 'isValid' => sub {
  ok( $v->isValid( 'Ab12' ),  'Valid input accepted' );
  ok( !$v->isValid( 'Ab!2' ), 'Invalid input rejected' );
};

subtest 'isValidInput' => sub {
  my $s1 = '123';
  ok( $v->isValidInput( $s1, 0 ), 'Valid partial input accepted' );
  is( $s1, '123', 'Input not modified' );

  my $s2 = '12!';
  ok( !$v->isValidInput( $s2, 1 ), 'Invalid partial input rejected' );
};

subtest 'Empty string' => sub {
  ok( $v->isValid( '' ), 'Empty string is valid' );
};

done_testing();
