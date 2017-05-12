use strict;
use Module::Build;
use Config;
use File::Spec;

my $build = new Module::Build (
	module_name	=> 'Bio::Polloc::Polloc::Root',
	description	=> 'Polymorphic Loci analysis',
	dist_name	=> 'Bio::Polloc',
	#dist_version_from	=> 'lib/Bio/Polloc/Polloc/Version.pm',
	dist_author	=> 'Luis M. Rodriguez-R <lmrodriguezr@gmail.com>',
	dist_abstract	=> 'Polymorphic Loci analysis',
	license		=> 'artistic_2',
	requires	=> {
		perl		=> '5.8.0',
		'Bio::SeqIO'	=> 0,
		'Config'	=> 0,
		'Cwd'		=> 0,
		'Error'		=> 0,
		'File::Path'	=> 0,
		'File::Spec'	=> 0,
		'File::Temp'	=> 0,
		'List::Util'	=> 0,
		'Symbol'	=> 0,
	},
	recommends	=> {
		'Bio::Tools::Run::Hmmer' => 0,
		'Bio::Tools::Run::StandAloneBlast' => 0,
		'Bio::Tools::Run::Alignment::Muscle' => 0,
		'File::Basename'=> 0,
		'GD::Simple'	=> 0,
	},
	build_requires		=> { 'Module::Build' => 0.20 },
	configure_requires	=> { 'Module::Build' => 0.36 },
	recursive_test_files	=> 1,
	create_makefile_pl	=> 'traditional',
);

if($build->y_n("Do you want to install the VNTR analysis tool scripts to $Config{installscript}?", 'n')){
   for my $pl (qw(vntrs primers gel)){
      $build->scripts( File::Spec->catfile('scripts', "polloc_$pl.pl") );
   }
}

if($build->y_n("Do you want to install the generic Polloc scripts to $Config{installscript}?", 'n')){
   for my $pl (qw(detect group experiment)){
      $build->scripts( File::Spec->catfile('scripts', "polloc_$pl.pl") );
   }
}

$build->create_build_script;

