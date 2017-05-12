#!/usr/bin/perl

use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open(CHANGES, ">>CHANGES") and close CHANGES;

WriteMakefile(
	NAME         => 'POE::Filter::Snort',
	AUTHOR       => 'Rocco Caputo <rcaputo@cpan.org>',
	ABSTRACT     => 'POE stream filter for parsing Snort logs',
	LICENSE      => 'perl',
	VERSION_FROM => 'Snort.pm',
	META_ADD     => {
		resources  => {
			license    => 'http://dev.perl.org/licenses/',
			repository => 'http://github.com/rcaputo/poe-filter-snort'
		},
	},
	PM           => { 'Snort.pm' => '$(INST_LIBDIR)/Snort.pm' },
	PREREQ_PM    => {
		'POE'        => 1.007,
		'Test::More' => 0,
	},
	dist         => {
		COMPRESS   => 'gzip -9f',
		SUFFIX     => 'gz',
		PREOP      => (
			'git-log.pl | tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
		),
	},
);
