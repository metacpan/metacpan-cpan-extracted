# Build.PL
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'POE::Devel::Benchmarker',
	'license'		=> 'perl',

	'dist_abstract'		=> "Benchmarking POE's performance ( acts more like a smoker )",
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'traditional',
	'create_readme'		=> 1,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'Makefile.PL', 'README' ],	# automatically generated

	'requires'		=> {
		# POE Stuff
		'POE'				=> 0,
		'POE::Session::AttributeBased'	=> 0,

		# FIXME POE stuff that Test::Dependencies needs to see
		'POE::Session'			=> 0,
		'POE::Wheel::SocketFactory'	=> 0,
		'POE::Wheel::ReadWrite'		=> 0,
		'POE::Filter::Line'		=> 0,
		'POE::Driver::SysRW'		=> 0,

		# misc perl stuff
		'Time::HiRes'			=> 0,
		'version'			=> 0,
		'Devel::Hide'			=> 0,

		# Analyzer reqs
		'YAML::Tiny'			=> 0,

		# GetPOEdists reqs
		'LWP::UserAgent'		=> 0,
		'HTML::LinkExtor'		=> 0,
		'URI::URL'			=> 0,
		'Archive::Tar'			=> 0,

		# Imager reqs
		'GD::Graph::lines'		=> 0,
		'GD::Graph::colour'		=> 0,
		'Class::Accessor::Fast'		=> 0,
		'Module::Pluggable'		=> 0,

		# Test stuff
		'Test::More'			=> '0.86',	# require latest for note() support in t/a_is_prereq_outdated.t
	},

	'recommends'		=> {
		# our POE loops!
		'POE::Loop::Event'		=> 0,
		'POE::Loop::Event_Lib'		=> 0,
		'POE::Loop::EV'			=> 0,
		'POE::Loop::Glib'		=> 0,
		'POE::Loop::Prima'		=> 0,
		'POE::Loop::Gtk'		=> 0,
		'POE::Loop::Wx'			=> 0,
		'POE::Loop::Kqueue'		=> 0,

		# included in POE ( listed here for completeness )
		#'POE::Loop::Tk'		=> 0,
		#'POE::Loop::Select'		=> 0,
		#'POE::Loop::IO_Poll'		=> 0,

		# the loops' dependencies
		'Event'				=> 0,
		'Event::Lib'			=> 0,
		'EV'				=> 0,
		'Glib'				=> 0,
		'Prima'				=> 0,
		'Wx'				=> 0,
		'Tk'				=> 0,

		# the XS stuff
		'POE::XS::Queue::Array'		=> 0,
		'POE::XS::Loop::Poll'		=> 0,
		'POE::XS::Loop::EPoll'		=> 0,
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
