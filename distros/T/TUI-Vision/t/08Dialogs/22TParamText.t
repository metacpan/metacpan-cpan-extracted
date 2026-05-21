use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::ParamText';
}

my ( $bounds, $param_text );

# Test case for the constructor
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 1 );
  $param_text = new_TParamText( $bounds );
  ok( $param_text, 'Object created' );
  isa_ok( $param_text, TParamText, 'Created object is correct class' );
}; #/ 'Object creation' => sub

# Test case for initial state
subtest 'Initial state' => sub {
  my $text = 'UNINITIALIZED';
  $param_text->getText( \$text );
  is( $text, '', 'Initial text should be empty string' );

  my $len = $param_text->getTextLen();
  is( $len, 0, 'Initial text length should be 0' );
};

# Test case for setText with simple string
subtest 'setText with simple string' => sub {
  lives_ok { $param_text->setText( 'Hello world' ) }
    'setText executed without error';

  my $text = '';
  $param_text->getText( \$text );
  is( $text, 'Hello world', 'getText returns the string set by setText' );

  my $len = $param_text->getTextLen();
  is( $len, length( 'Hello world' ), 'getTextLen matches actual text length' );
}; #/ 'setText with simple string' => sub

# Test case for setText with format string
subtest 'setText with format string' => sub {
  lives_ok { $param_text->setText( 'Value=%d, Name=%s', 42, 'John' ) } 
    'setText with format string executed without error';

  my $text = '';
  $param_text->getText( \$text );
  my $expected = 'Value=42, Name=John';
  is( $text, $expected, 'Formatted text stored correctly' );
  my $len = $param_text->getTextLen();
  is( $len, length( $expected ), 'Length of formatted text is correct' );
}; #/ 'setText with format string' => sub

done_testing();
