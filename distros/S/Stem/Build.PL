use strict;
use warnings ;

use Config;
use File::Spec;

use BuildStem ;

my $is_win32 = ( $^O =~ /Win32/) ? 1 : 0 ;

my %requires ;

my $version_from = File::Spec->catfile( File::Spec->curdir, 'lib', 'Stem.pm' );

my $build = BuildStem->new(
	module_name		=> 'Stem',
	dist_version_from	=> $version_from,
	requires		=> \%requires,
	license			=> 'gpl',
	dynamic_config		=> 1,
	recursive_test_files	=> 1,
	create_makefile_pl	=> 'passthrough'
);

# since we are making a fresh Build script, delete any older stem config file
# so Build will create a new one.

my $conf_pm_file = $build->config_pm_path() ;
unlink $conf_pm_file ;

$build->create_build_script() ;

exit ;
