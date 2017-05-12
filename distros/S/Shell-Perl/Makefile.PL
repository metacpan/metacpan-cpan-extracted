use strict;
use warnings;

use 5.008;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile
(
	NAME         => 'Shell::Perl',
	VERSION_FROM => 'lib/Shell/Perl.pm',
	EXE_FILES    => [ 'bin/pirl' ],
	PREREQ_PM    =>
	{
		'Class::Accessor' => 0,
		'File::Basename'  => 0,
		'File::HomeDir'   => 0,
		'Getopt::Long'    => 2.43,    # bundling_values
		'IPC::Cmd'	      => 0,
		'Path::Class'     => 0.34,    # spew_lines()
		'Test::Deep'      => 0,
		'Test::More'      => 0,
		'Term::ReadLine'  => 0,
		'version'         => 0.77,    # parse()
    },

	($] >= 5.005 ? (
		ABSTRACT_FROM  => 'lib/Shell/Perl.pm',
		AUTHOR	 => 'A. R. Ferreira <ferreira@cpan.org>',
	) : ()),

	($EUMM_VERSION >= 6.31 ? (
		LICENSE => 'perl',
	) : ()),

	($EUMM_VERSION > 6.4501 ? (
	META_MERGE =>
	{
		recommends =>
		{
			# optional tests
			'Test::Pod'	   => 0,
			'Test::Pod::Coverage' => 0,
			'Test::Script'	=> 0,
			'Test::Expect'	=> 0,
		},
		resources =>
		{
			repository => 'http://github.com/aferreira/pirl',
	 	},
	},
	) : ()),
);

# recommended:
#
#   - -one_of: [ YAML::Syck, YAML ]
#   - Data::Dump
#   - Data::Dumper
#   - Data::Dump::Streamer
#
