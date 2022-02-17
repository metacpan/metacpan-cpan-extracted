use Module::Build;
use strict;
use warnings;
use PDL::Core::Dev;
use Prima::Config;
use Config;

# These are lifted from PDL::Core::Dev, but use a less redundant style:
my $inc = PDL_INCLUDE;
$inc =~ s/-I//g;
$inc =~ s/"//g;
my @incs = ($inc, @{$Prima::Config::Config{incpaths}});

# Explicitly set the version here; all .pm.PL files will use this:
my $version = '0.14';

my $build = Module::Build->new(
	module_name => 'PDL::Drawing::Prima',
	dist_version_from => 'lib/PDL/Drawing/Prima.pm.PL',
	dist_version => $version,
	license  => 'perl',
	configure_requires => {
		PDL						=> '2.037',
		Prima					=> '1.57',
		# meta_merge was added in v 0.28:
		'Module::Build'		=> 0.28,
	},
	build_requires => {
		# working here - I need to check the smoke reports to hone in on a
		# minimum required version:
		'ExtUtils::ParseXS'	=> '3.0',
	},
	requires => {
		# Due to the use of Prima, I need at least 5.10:
		perl					=> '5.10.0',
		PDL						=> '2.037',
		Prima					=> '1.57',
	},
	needs_compiler => 1,
	include_dirs => \@incs,
	meta_merge => {
		resources => {
			repository
				=> 'http://github.com/run4flat/PDL-Drawing-Prima',
#				=> {
#					web => 'http://github.com/run4flat/PDL-Drawing-Prima',
#					url => 'git://github.com/run4flat/PDL-Drawing-Prima.git',
#					type => 'git',
#				},
			bugtracker
				=> 'http://github.com/run4flat/PDL-Drawing-Prima/issues',
#				=> {
#					web => 'http://github.com/run4flat/PDL-Drawing-Prima/issues',
#				},
		},
		provides => {
			'PDL::Drawing::Prima' => {
				file => 'lib/PDL/Drawing/Prima.pm.PL',
				version => $version,
			},
			'PDL::Drawing::Prima::Utils' => {
				file => 'lib/PDL/Drawing/Prima/Utils.pm.PL',
				version => $version,
			},
		},
		no_index => {
			file => ['README.pod'],
			directory => [qw(examples t)],
		},
	},
);

# Link to Prima's dynamic library if there are any linker settings.
# (Big shout out to Dmitry, Rob, and Chris for helping me solve this!!)
$build->extra_linker_flags(split(/\s+/, $Prima::Config::Config{libs}))
	if $Prima::Config::Config{libs};


$build->create_build_script;
