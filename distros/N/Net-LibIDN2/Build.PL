# vim:set tabstop=4 shiftwidth=4 noexpandtab:

use strict;
use warnings;

use lib 'inc';
use Devel::CheckLib;

my ($incpath, $libpath) = @_;

foreach (@ARGV)
{
	$incpath = $1 if m/--extra_compiler_flags=.*-I(\S+)\s*/;
	$libpath = $1 if m/--extra_linker_flags=.*-L(\S+)\s*/;
}

check_lib_or_exit(
	lib => 'idn2', 
	header => 'idn2.h',
	function => 'if (idn2_check_version("0.8")) return 0; else return 1;',
	incpath => $incpath,
	libpath => $libpath
);

use Module::Build;

my $build = Module::Build->new
(
	module_name => 'Net::LibIDN2',

	license  => 'perl',

	dist_author => 'Thomas Jacob <jacob@internet24.de>',

	dynamic_config => 1,

	create_license => 1,

	extra_compiler_flags => '',
	extra_linker_flags   => '-lidn2',

	build_requires =>
	{
		'ExtUtils::CBuilder' => 0,
		'ExtUtils::ParseXS' => 0,
		'Test::More' => '0.10',
	},

	requires =>
	{
		'perl' => '5.6.1',
	},

	meta_merge =>
	{
		resources => {
			repository  => 'https://github.com/gnuthor/Net--LibIDN2',
			homepage    => 'https://metacpan.org/release/Net-LibIDN2',
			bugtracker  => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Net-LibIDN2',
		},
	},
);
												    
$build->create_build_script;
