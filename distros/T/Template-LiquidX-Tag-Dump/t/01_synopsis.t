use strict;
use Test::More 0.98;
use Template::Liquid;
use Template::LiquidX::Tag::Dump;
#
is (
	Template::Liquid->parse("{%dump var%}")->render(var => [qw[some sort of data here]]),
	(
		$Data::Dump::VERSION ?
		'["some", "sort", "of", "data", "here"]' :
		q"$VAR1 = [
          'some',
          'sort',
          'of',
          'data',
          'here'
        ];
"
),	
	'synopsis');
#
done_testing;
