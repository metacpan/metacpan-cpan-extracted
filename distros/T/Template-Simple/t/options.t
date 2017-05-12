#!perl

use lib qw(t) ;
use common ;

my $tests = [

	{
		name	=> 'pre_delim',
		opts	=> {
			pre_delim => '<%',
		},
		data	=> {
			foo	=> 'FOO is 3',
			BAR	=> 'bar is baz',
		},
		template => <<TEMPLATE,
<%foo%]
<%BAR%]
TEMPLATE
		expected => <<EXPECTED,
FOO is 3
bar is baz
EXPECTED
	},
	{
		name	=> 'post_delim',
		opts	=> {
			post_delim => '%>',
		},
		data	=> {
			foo	=> 'FOO is 3',
			BAR	=> 'bar is baz',
		},
		template => <<TEMPLATE,
[%foo%>
[%BAR%>
TEMPLATE
		expected => <<EXPECTED,
FOO is 3
bar is baz
EXPECTED
	},
	{
		name	=> 'pre/post_delim',
		opts	=> {
			pre_delim => '<%',
			post_delim => '%>',
		},
		data	=> {
			foo	=> 'FOO is 3',
			BAR	=> 'bar is baz',
		},
		template => <<TEMPLATE,
<%foo%>
<%BAR%>
TEMPLATE
		expected => <<EXPECTED,
FOO is 3
bar is baz
EXPECTED
	},
	{
		name	=> 'pre/post_delim regexes',
		opts	=> {
			pre_delim => qr/A+/,
			post_delim => qr/B+/,
		},
		data	=> {
			foo	=> 'FOO is 3',
			bAR	=> 'bar is baz',
		},
		template => <<TEMPLATE,
AAAfooBBBBB
AbARB
TEMPLATE
		expected => <<EXPECTED,
FOO is 3
bar is baz
EXPECTED
	},
	{
		name	=> 'chunk delim',
		opts	=> {
			pre_delim => '<%',
			post_delim => '%>',
		},
		data	=> {
			foo	=> { FOO => 3 },
			bar	=> { BAR => 4 },
		},
		template => <<TEMPLATE,
<%START foo%>
<%FOO%>
<%END foo%>
<%START bar%><%BAR%><%END bar%>
TEMPLATE
		expected => <<EXPECTED,

3

4
EXPECTED
	},

	{
		name	=> 'chunk delim - array of hashes',
		opts	=> {
			pre_delim => '<%',
			post_delim => '%>',
		},
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
<%START foo%>
<%FOO%>
<%END foo%>
<%START bar%><%BAR%><%END bar%>
TEMPLATE
		expected => <<EXPECTED,

3

4

6

quux
EXPECTED
	},
	{
		name	=> 'greedy chunk',
		opts	=> {
			greedy_chunk	=> 1,
		},
		data	=> {
			FOO	=> 'foo',
		},
		template => <<TEMPLATE,
[%START FOO%]
[%START FOO%]
bar
[%END FOO%]
[%END FOO%]
TEMPLATE
		expected => <<EXPECTED,
foo
EXPECTED
	},
	{
		name	=> 'not greedy chunk',
		opts	=> {
			greedy_chunk	=> 0,
		},
		data	=> {
			FOO	=> 'foo',
		},
		template => <<TEMPLATE,
[%START FOO%]
[%START FOO%]
bar
[%END FOO%]
[%END FOO%]
TEMPLATE
		expected => <<EXPECTED,
foo
[%END FOO%]
EXPECTED
	},
	{
		name	=> 'token_re',
		opts	=> {
			token_re => qw/[-\w]+?/,
		},
		data	=> {
			'foo-bar'	=> 'FOO is 3',
			'BAR-BAZ'	=> 'bar is baz',
		},
		template => <<TEMPLATE,
[%foo-bar%]
[%BAR-BAZ%]
TEMPLATE
		expected => <<EXPECTED,
FOO is 3
bar is baz
EXPECTED
	},
] ;

template_tester( $tests ) ;

exit ;
