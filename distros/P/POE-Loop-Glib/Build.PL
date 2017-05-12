# Build.PL
use strict; use warnings;
use Module::Build;

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'POE::Loop::Glib',
	'license'		=> 'gpl',

	'dist_abstract'		=> "A bridge that supports Glib's event loop from POE",
	'dist_author'		=> 'Martijn van Beers  <martijn@cpan.org>',

	# TODO We don't auto-gen LICENSE because we want gplv2 :(
	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'passthrough',
	'create_readme'		=> 1,
	'sign'			=> 0,

	'test_files'		=> [ 't/*.t', 't/glib/*.t' ],

	'add_to_cleanup'	=> [ 'run_network_tests', 't/glib/*', 't/glib', ],

	'configure_requires'		=> {
		'POE::Test::Loops'	=> '1.034',
	},

	'requires'		=> {
		# core modules we need
		'POE'		=> '1.288',
		'Glib'		=> '1.222',

		# minimum perl version
		'perl'		=> '5.006',
	},

	'recommends'		=> {
		'Win32::Console'	=> 0,
		'Term::Readkey'		=> 0,
		'Socket6'		=> 0,
		'IO::Pty'		=> 0,
	},

	# include the standard stuff in META.yml
	'meta_merge'	=> {
		'resources'	=> {
			'license'	=> 'http://dev.perl.org/licenses/',
			'homepage'	=> 'http://search.cpan.org/dist/POE-Loop-Glib',
			'bugtracker'	=> 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Loop-Glib',
			'repository'	=> 'http://github.com/apocalypse/perl-poe-loop-glib',
		},
	},
);

# Ask the user for network access
my $prompt = (
	"Some of POE's tests require a functional network.\n" .
	"You can skip these tests if you'd like.\n\n" .
	"Would you like to skip the network tests? "
);

my $ret = $build->prompt( $prompt, "n" );
my $marker = 'run_network_tests';
unlink $marker if -f $marker;
unless ($ret =~ /^Y$/i) {
	open(TOUCH,"+>$marker") and close TOUCH;
}

# Generate the PTL tests
$build->do_system( $^X, '-MPOE::Test::Loops', '-e', 'POE::Test::Loops::generate( "t/", [ "Glib" ], 0)' );

# all done!
$build->create_build_script;
