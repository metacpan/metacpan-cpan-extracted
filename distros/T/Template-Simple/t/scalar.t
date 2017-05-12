#!perl

use lib qw(t) ;
use common ;

my $tests = [

	{
#		skip	=> 1,
		name	=> 'simple scalar',
		data	=> {
			foo	=> 'FOO is 3',
			BAR	=> 'bar is baz',
		},
		template => <<TEMPLATE,
[%foo%]
junk
[%BAR%]
TEMPLATE
		expected => <<EXPECTED,
FOO is 3
junk
bar is baz
EXPECTED
	},

	{
#		skip	=> 1,
		name	=> 'simple chunk - hash data',
		data	=> {
			foo	=> { FOO => 3 },
			bar	=> { BAR => 4 },
		},
		template => <<TEMPLATE,
[%START foo%]
[%FOO%]
[%END foo%]
[%START bar%][%BAR%][%END bar%]
TEMPLATE
		expected => <<EXPECTED,

3

4
EXPECTED
	},

	{
#		skip	=> 1,
		name	=> 'simple chunk - scalar data',
		data	=> {
			foo	=> 3,
			bar	=> { BAR => 4 },
		},
		template => <<TEMPLATE,
[%START foo%]
FOO
[%END foo%]
[%START bar%][%BAR%][%END bar%]
TEMPLATE
		expected => <<EXPECTED,
3
4
EXPECTED
	},
	{
#		skip	=> 1,
		name	=> 'simple chunk - array of hashes',
		data	=> [
			{
				foo	=> { FOO => 3 },
				bar	=> { BAR => 4 },
			},
			{
				foo	=> { FOO => 6 },
				bar	=> { BAR => 'quux' },
			}
		],
		template => <<TEMPLATE,
[%START foo%]
[%FOO%]
[%END foo%]
[%START bar%][%BAR%][%END bar%]
TEMPLATE
		expected => <<EXPECTED,

3

4

6

quux
EXPECTED
	},
] ;

template_tester( $tests ) ;

exit ;

