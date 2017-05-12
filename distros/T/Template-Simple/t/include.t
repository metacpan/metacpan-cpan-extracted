#!perl

use strict ;
use lib qw(t) ;
use common ;

use File::Slurp ;
use Data::Dumper ;

# these dirs must be in order to the deepest for rmdir to work properly

my @tmpl_dirs = qw( templates templates/deeper templates/deeper/deepest ) ;

my %tmpl_files = (

	'templates/FOO.tmpl'	=> <<FOO,
this loads bar <[%include BAR%]>
FOO
	'templates/deeper/BAR.tmpl'	=> <<BAR,
{this should hide}
BAR
	'templates/deeper/deepest/BAR.tmpl'	=> <<BAR,
[this should be hidden then revealed]
BAR

) ;

my $tests = [
	{
		name	=> 'simple include',
		skip	=> 0,
		opts	=> {
			templates => {
				'foo'	=> 'bar',
			}
		},
		data	=> {},
		template => '[%INCLUDE foo%]',
		expected => 'bar',
	},
	{
		name	=> 'nested includes',
		skip	=> 0,
		opts	=> {
			templates => {
				foo	=> '[%include bar%]',
				bar	=> 'quux',
			},
		},
		data	=> {},
		template => '[%INCLUDE foo%]',
		expected => 'quux',
	},
	{
		name	=> 'serial includes',
		skip	=> 0,
		opts	=> {
			templates => {
				foo	=> 'foo is here',
				bar	=> 'bar is too',
				quux	=> 'quux is on the drums',
			},
		},
		data	=> {},
		template => '[%INCLUDE foo%] [%INCLUDE bar%] [%INCLUDE quux%]',
		expected => 'foo is here bar is too quux is on the drums',
	},
	{
		name	=> 'missing include',
		skip	=> 0,
		data	=> {},
		keep_obj => 1,
		pretest	=> sub { $_[0]{obj}->delete_templates() },
		error	=> qr/can't find/,
	},
	{
		name	=> 'load include files',
		skip	=> 0,
		opts	=> {
			search_dirs => [ qw(
				templates
				templates/deeper
				templates/deeper/deepest
			) ],
		},
		data	=> {},
		template => '[%INCLUDE FOO%]',
		expected => <<EXPECTED,
this loads bar <{this should hide}
>
EXPECTED

	},
	{
		name	=> 'use lower path',
		skip	=> 0,
		opts	=> {
			include_paths => [ qw(
				templates
				templates/deeper/deepest
			) ],
		},
		data	=> {},
		expected => <<EXPECTED,
this loads bar <[this should be hidden then revealed]
>
EXPECTED

	},
	{
		name	=> 'delete covering file',
		skip	=> 0,
		opts	=> {
			search_dirs => [ qw(
				templates
				templates/deeper
				templates/deeper/deepest
			) ],
		},
		pretest	=> sub { unlink 'templates/deeper/BAR.tmpl' },
		posttest => sub { write_tmpl_files() },

		data	=> {},
		expected => <<EXPECTED,
this loads bar <[this should be hidden then revealed]
>
EXPECTED

	},
] ;


write_tmpl_files() ;

template_tester( $tests ) ;

#remove_tmpl_files() ;

exit ;


sub write_tmpl_files {

	mkdir $_, 0755 for @tmpl_dirs ;

	while( my( $file, $tmpl ) = each %tmpl_files ) {

		write_file( $file, $tmpl ) ;
	}
}

sub remove_tmpl_files {

	unlink keys %tmpl_files ;
	rmdir $_ for reverse @tmpl_dirs ;
}
