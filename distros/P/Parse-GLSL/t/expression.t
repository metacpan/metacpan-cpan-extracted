use strict;
use warnings;

use Test::More tests => 11;
use Test::Deep;

use Parse::GLSL;
my $parser = new_ok('Parse::GLSL');
sub parse_as {
	my ($method, $str, $expected, $msg) = @_;
	# eww
	$parser->{str} = $str;
	# eww again
	pos $parser->{str} = 0;
	$method = "parse_$method";
	my $rslt = $parser->$method;
	cmp_deeply($rslt, $expected, $msg) or note explain $rslt;
	ok($parser->at_eos, 'and have reached end of string');
}

parse_as(expression => '1.0', 1.0, 'simple float');
parse_as(expression => '1.0 + 3.0', [ 1.0, '+', 3.0 ], 'add two numbers');
parse_as(expression => '1.0 + fract(3.0)', [ 1.0, '+', [ fract => [ 3.0 ] ] ], 'add number and function result');
parse_as(expression => 'sin(1.0) + fract(3.0)', [
	[ 'sin', [ 1.0 ] ],
	'+',
	[ fract => [ 3.0 ] ]
], 'add two function results');
parse_as(expression => 'mix(sin(1.0) + fract(3.0), cos(0.5 + fract(2.0)))', [
	mix => [
		[
			[ 'sin' => [ 1.0 ] ],
			'+',
			[ fract => [ 3.0 ] ]
		],
		[
			'cos' => [
				[ 0.5, '+', [ fract => [ 2.0 ] ] ]
			]
		]
	]
], 'something more nested');

