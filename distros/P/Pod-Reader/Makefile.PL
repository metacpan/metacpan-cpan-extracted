use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Pod::Reader',
	AUTHOR       => 'Patrice Clement <monsieurp@cpan.org>',
	VERSION_FROM => 'lib/Pod/Reader.pm',
	ABSTRACT     => 'curses TUI to read Perl POD from.',
	LICENSE      => 'bsd',
	EXE_FILES    => [ 'bin/podreader' ],
	MIN_PERL_VERSION   => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
        'Curses::UI'      => '0.9609',
        'Curses'          => '1.36',
        'Carp'            => '0',
        'File::Find'      => '0',
        'Getopt::Long'    => '0',
        'Pod::Usage'      => '0',
        'Term::ANSIColor' => '0'
	},
	TEST_REQUIRES => {
		'Test::More'    => '0',
		'Capture::Tiny' => '0',
	},
	META_MERGE => {
		name        => 'Pod-Reader',
		licence     => [ 'bsd' ],
		'meta-spec' => { version => 2 },
		resources   => {
			homepage   => 'https://github.com/monsieurp/Pod-Reader',
			license    => [ 'https://opensource.org/licenses/BSD-3-Clause' ],
			repository => {
				type => 'git',
				url  => 'https://github.com/monsieurp/Pod-Reader.git',
				web  => 'https://github.com/monsieurp/Pod-Reader'
			},
			bugtracker => {
				web => 'https://github.com/monsieurp/Pod-Reader/issues'
			},
		},
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'Pod-Reader-*' },
);
