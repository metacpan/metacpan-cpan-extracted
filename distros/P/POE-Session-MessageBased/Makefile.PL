#!/usr/bin/perl

use ExtUtils::MakeMaker;

# Touch CHANGES so MakeMaker will see it.
open(CHANGES, ">>CHANGES") and close CHANGES;

WriteMakefile(
	NAME          => 'POE::Session::MessageBased',
	AUTHOR        => 'Rocco Caputo <rcaputo@cpan.org>',
	ABSTRACT      => 'Message-based events for POE (no @_ slices)',
	LICENSE       => 'perl',
	VERSION_FROM  => 'MessageBased.pm',
	PM            => {
		'MessageBased.pm' => '$(INST_LIBDIR)/MessageBased.pm'
	},
	META_ADD     => {
		resources  => {
			license    => 'http://dev.perl.org/licenses/',
			repository => 'http://github.com/rcaputo/poe-session-messagebased'
		},
	},
	dist          => {
		'COMPRESS'  => 'gzip -9f',
		'SUFFIX'    => 'gz',
		PREOP       => (
			'git-log.pl  | tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
		),
	},
	PREREQ_PM     => {
		'POE'        => 1.007,
		'Test::More' => 0,
	},
);
