#!perl

use lib qw(t) ;
use common ;

my $tests = [
	{
		name	=> 'unknown template data type',
		compile_skip	=> 1,
		opts	=> {},
		data	=> qr//,
		template => <<TMPL,
foo
TMPL
		expected => <<EXPECT,
bar
EXPECT
		error => qr/unknown template data/,
	},
	{
		name	=> 'missing include',
		skip	=> 0,
		data	=> {},
		template => '[%INCLUDE foox%]',
		error	=> qr/can't find/,
	},
	{
		name	=> 'code data',
		compile_skip	=> 1,
		skip	=> 0,
		data	=> sub { return '' },
		template => 'bar',
		error	=> qr/data callback/,
	},
] ;

template_tester( $tests ) ;

exit ;

