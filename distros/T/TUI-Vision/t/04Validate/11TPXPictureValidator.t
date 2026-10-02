use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Validate::PXPictureValidator';
  use_ok 'TUI::Validate::Const';
}

my $v;

subtest 'Object creation' => sub {
  lives_ok {
    $v = TPXPictureValidator->new(
      pic      => '##??',
      autoFill => !!0,
    );
  }
  'Validator object created';

  isa_ok( $v, TPXPictureValidator );
};

subtest 'Simple valid input' => sub {
  my $s = '12ab';
  ok(
    $v->isValid( $s ),
    'Valid input matches picture'
  );
  is( $s, '12ab', 'Input not modified without autofill' );
};

subtest 'Invalid input' => sub {
  my $s = '1aab';
  ok(
    !$v->isValid( $s ),
    'Invalid input rejected'
  );
};

subtest 'Uppercase conversion with &' => sub {
  my $v = TPXPictureValidator->new(
    pic      => '&?',
    autoFill => !!0,
  );

  my $s = 'ab';
  ok(
    $v->isValidInput( $s, 1 ),
    'Letter input accepted for in-progress validation'
  );
  is(
    $s,
    'Ab',
    'First character uppercased by & in isValidInput'
  );

  my $final = 'ab';
  ok(
    $v->isValid( $final ),
    'Letter input accepted for final validation'
  );
  is(
    $final,
    'ab',
    'isValid keeps input unchanged (const-like semantics)'
  );
};

subtest 'Literal matching' => sub {
  my $v = TPXPictureValidator->new(
    pic      => 'A-##',
    autoFill => !!0,
  );

  my $ok  = 'A-12';
  my $bad = 'A_12';

  ok( $v->isValid( $ok ),   'Literal "-" matches' );
  ok( !$v->isValid( $bad ), 'Literal mismatch rejected' );
};

subtest 'AutoFill appends literals' => sub {
  my $v = TPXPictureValidator->new(
    pic      => '##-##',
    autoFill => !!1,
  );

  my $s = '12';
  ok(
    $v->isValidInput( $s, 0 ),
    'Input accepted with autofill'
  );

  is(
    $s,
    '12-',
    'Literal "-" autofilled'
  );
};

subtest 'Iteration (*) exact count' => sub {
  my $v = TPXPictureValidator->new(
    pic      => '*3#',
    autoFill => !!0,
  );

  my $ok  = '123';
  my $bad = '12';

  ok( $v->isValid( $ok ),   'Exact iteration count accepted' );
  ok( !$v->isValid( $bad ), 'Too few iterations rejected' );
};

subtest 'Optional group []' => sub {
  my $v = TPXPictureValidator->new(
    pic      => '##[??]',
    autoFill => !!0,
  );

  my $s1 = '12';
  my $s2 = '12ab';

  ok( $v->isValid( $s1 ), 'Optional group omitted' );
  ok( $v->isValid( $s2 ), 'Optional group present' );
};

subtest 'Empty picture disables validator' => sub {
  my $v = TPXPictureValidator->new(
    pic      => '',
    autoFill => !!0,
  );

  my $s = 'anything';
  ok(
    $v->isValid( $s ),
    'Empty picture accepts any input'
  );
};

done_testing();
