use strict;
use warnings;

use Module::Build;

# Determine RPM version
`pkg-config --modversion rpm` =~ /(\d+)\.(\d+)/
	or die 'Can not determine RPM version. '.
		'Ensure rpm-devel >= 4.6 is installed';
my $api_version = sprintf '-DRPM2_API=%i%03i ', $1, $2;

my $build = new Module::Build (
	module_name => 'RPM2',
	license => 'perl',
	dist_author => 'Lubomir Rintel <lkundrak@v3.sk>',
	dist_version_from => 'lib/RPM2.pm',
	meta_merge => {
		resources => {
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=RPM2',
			repository => 'https://github.com/lkundrak/perl-RPM2.git',
		}
	},
	requires => {
		'File::Basename' => 0,
		'File::Spec' => 0,
	},
	extra_compiler_flags => $api_version.scalar `pkg-config rpm --cflags`,
	extra_linker_flags => scalar `pkg-config rpm --libs`,
	build_requires => {
		'ExtUtils::CBuilder' => 0,
	},
);

$build->create_build_script;
