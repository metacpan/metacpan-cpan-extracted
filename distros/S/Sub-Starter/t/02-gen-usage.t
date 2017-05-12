#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Sub::Starter' );
}

my ( $name, $sub, $test, $expected );
my $template = [ "\e[1m(usage)\e[0m" ];

# --------------------------------------
$name = 'foo';
$sub = Sub::Starter->new();
$sub->parse_usage( 'foo' );
$test = $sub->fill_out( $template );
$expected = 'foo();';
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'trim';
$sub = Sub::Starter->new();
$sub->parse_usage( '$text | @text = trim( @text );' );
$test = $sub->fill_out( $template );
$expected = '$text | @text = trim( @text );';
is_deeply( $test, $expected, $name );

# --------------------------------------
$name = 'get_options';
$sub = Sub::Starter->new();
$sub->parse_usage( '\%options = $object->get_options( ; @option_names );' );
$test = $sub->fill_out( $template );
$expected = '\\%options = $object->get_options( ; @option_names );';
is_deeply( $test, $expected, $name );


__END__
