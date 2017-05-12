use strict;
use utf8;
use Test::More;
use Parse::JCONF;
use Parse::JCONF::Boolean qw(TRUE FALSE);

my $parser = Parse::JCONF->new(autodie => 1);
my $res = $parser->parse_file('t/files/complex.jconf');

is_deeply($res, {
	array_of_empty_objects => [{},{},{}],
	object_of_empty_arrays => {0 => [], 1=> [], 2 => []},
	not_true               => FALSE,
	hash                   => {
		ke1 => [
			1,
			FALSE,
			undef,
			"перл!", 
			{h => 1}
		],
		key2 => {
			'f' => FALSE,
			't' => TRUE,
			'n' => undef,
			's' => 'string with "quotes"',
			'o' => {name => "object"},
			'a' => ["array",""]
		},
		key3 => [undef,FALSE,TRUE]
	},
	array                  => [
		{
			complex => [{
				complex => {
					very_complex => TRUE
				}
			}]
		},
		[{}],
		{
			str       =>
"Multiline
String",
			num_array => [1,-1,1.1,-1.1,1E-1,-1E2]
		}
	]
}, "parse complex structures");

done_testing;
