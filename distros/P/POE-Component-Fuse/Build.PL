# Build.PL
use strict; use warnings;
use Module::Build;

# we trust Fuse.pm to correctly install + detect versions so we don't do it here
my $inc = '-Wall -DFUSE_USE_VERSION=25 ' . `pkg-config --cflags fuse` || '-I ../include -D_FILE_OFFSET_BITS=64';
my $obj = `pkg-config --libs fuse` || '-lfuse';
chomp $inc; chomp $obj; # sometimes pkg-config prints out extra newline
#$inc .= '-g -ggdb';	# used for debugging
$inc .= ' -D__FreeBSD__=10 -D_FILE_OFFSET_BITS=64' if $^O eq 'darwin';

my $build = Module::Build->new(
	# look up Module::Build::API for the info!
	'dynamic_config'	=> 0,
	'module_name'		=> 'POE::Component::Fuse',
	'license'		=> 'perl',

	'dist_abstract'		=> "Using FUSE in POE",
	'dist_author'		=> 'Apocalypse <APOCAL@cpan.org>',

	'create_packlist'	=> 1,
	'create_makefile_pl'	=> 'passthrough',	# not traditional, because it won't compile XS correctly
	'create_readme'		=> 1,

	'test_files'		=> 't/*.t',

	'add_to_cleanup'	=> [ 'META.yml', 'Makefile.PL', 'README', 'Makefile' ],	# automatically generated

	# set our XS stuff
	'extra_compiler_flags'	=> $inc,
	'extra_linker_flags'	=> $obj,

	'requires'		=> {
		# POE Stuff
		'POE'				=> 0,
		'POE::Session::AttributeBased'	=> 0,

		# FIXME POE stuff that Test::Dependencies needs to see
		'POE::Session'			=> 0,
		'POE::Wheel::Run'		=> 0,
		'POE::Filter::Reference'	=> 0,
		'POE::Filter::Line'		=> 0,

		# system constants
		'Errno'				=> 0,
		'Fcntl'				=> 0,
		'Config'			=> 0,
		'Carp'				=> 0,
		'DynaLoader'			=> 0,

		# to find out stuff about $fh
		'Scalar::Util'			=> 0,

		# Filesys::Virtual wrapper
		'Fuse::Filesys::Virtual'	=> 0,

		# Async stuff for better integration with POE
		'Filesys::Virtual::Async'	=> 0,
		'POE::Component::AIO'		=> 0,

		# set our minimum perl version
		'perl'				=> '5.006',
	},
);

# all done!
$build->create_build_script;
