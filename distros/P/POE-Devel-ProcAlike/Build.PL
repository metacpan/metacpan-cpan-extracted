# Build.PL
use strict; use warnings;
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'POE::Devel::ProcAlike',
	'license'		=> 'perl',

	'dist_abstract'		=> "Exposing POE guts via FUSE",
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'Makefile.PL', 'README' ],	# automatically generated

	'build_requires'	=> {
		# Test stuff
		'Test::More'			=> '0.86',	# require latest for note() support in t/a_is_prereq_outdated.t
	},

	'requires'		=> {
		# POE Stuff
		'POE'				=> '1.003',	# require latest for sanity
		'POE::Session::AttributeBased'	=> 0,
		'POE::API::Peek'		=> 0,

		# our FUSE stuff
		'Fuse'				=> '0.09',
		'POE::Component::Fuse'		=> '0.02',
		'POE::Component::AIO'		=> 0,

		# the FsV objects
		'Filesys::Virtual::Async::inMemory'	=> 0,
		'Filesys::Virtual::Async::Dispatcher'	=> 0,

		# our minimum perl version
		'perl'				=> '5.006',
	},

	# FIXME wishlist...
#	'test_requires'		=> {
#		# Test stuff
#		'Test::Compile'		=> 0,
#		'Test::Perl::Critic'	=> 0,
#		'Test::Dependencies'	=> 0,
#		'Test::Distribution'	=> 0,
#		'Test::Fixme'		=> 0,
#		'Test::HasVersion'	=> 0,
#		'Test::Kwalitee'	=> 0,
#		'Test::CheckManifest'	=> 0,
#		'Test::MinimumVersion'	=> 0,
#		'Test::Pod::Coverage'	=> 0,
#		'Test::Spelling'	=> 0,
#		'Test::Pod'		=> 0,
#		'Test::Prereq'		=> 0,
#		'Test::Strict'		=> 0,
#		'Test::UseAllModules'	=> 0,
#		'Test::YAML::Meta'	=> 0,
#	},
);

# all done!
$build->create_build_script;
