#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Sub::Starter' );
}

my ( $name, $test, $expected );

# --------------------------------------
$name = 'new';
$test = Sub::Starter->new();
$expected = {
  '-assignment' => '\'\'',
  '-max_usage' => 0,
  '-max_variable' => 0,
  '-name' => '',
  '-object' => '',
  '-parameters' => [],
  '-returns' => [],
  '-returns_alternate' => ''
};
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'foo';
$test = Sub::Starter->new();
$test->parse_usage( 'foo' );
$expected = {
  '-assignment' => '\'\'',
  '-max_usage' => 0,
  '-max_variable' => 0,
  '-name' => 'foo',
  '-object' => '',
  '-parameters' => [],
  '-returns' => [],
  '-returns_alternate' => ''
};
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'trim';
$test = Sub::Starter->new();
$test->parse_usage( '$text | @text = trim( @text );' );
$expected = {
  '-assignment' => '\'\'',
  '-max_usage' => 5,
  '-max_variable' => 5,
  '-name' => 'trim',
  '-object' => '',
  '-parameters' => [
    {
      '-type' => 'array',
      '-usage' => '@text',
      '-variable' => '@text'
    }
  ],
  '-returns' => [
    {
      '-type' => 'array',
      '-usage' => '@text',
      '-variable' => '@text'
    }
  ],
  '-returns_alternate' => {
    '-type' => 'scalar',
    '-usage' => '$text',
    '-variable' => '$text'
  }
};
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'get_options';
$test = Sub::Starter->new();
$test->parse_usage( '\%options = $object->get_options( ; @option_names );' );
$expected = {
  '-assignment' => '\'\'',
  '-max_usage' => 13,
  '-max_variable' => 13,
  '-name' => 'get_options',
  '-object' => '$object',
  '-parameters' => [
    {
      '-type' => 'array',
      '-usage' => '@option_names',
      '-variable' => '@option_names',
      'optional' => 1
    }
  ],
  '-returns' => [
    {
      '-type' => 'hash_ref',
      '-usage' => '\\%options',
      '-variable' => '$options'
    }
  ],
  '-returns_alternate' => ''
};
is_deeply( $test, $expected, $name );


__END__
# --------------------------------------
$name = 'new';
$test = Sub::Starter->new();
$test->parse_usage( '$text | @text = trim( @text );' );
$expected = {
  '-assignment' => '\'\'',
  '-max_usage' => 0,
  '-max_variable' => 0,
  '-name' => '',
  '-object' => '',
  '-parameters' => [],
  '-returns' => [],
  '-returns_alternate' => ''
};
is_deeply( $test, $expected, $name );

