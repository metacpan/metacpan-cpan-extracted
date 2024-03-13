#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;
WriteMakefile(
	NAME             => 'Regexp::IntInequality',
	AUTHOR           => 'Hauke D <haukex@zero-g.net>',
	LICENSE          => 'lgpl_3_0',
	VERSION_FROM     => 'lib/Regexp/IntInequality.pm',
	ABSTRACT_FROM    => 'lib/Regexp/IntInequality.pm',
	MIN_PERL_VERSION => '5.8.9',
	META_MERGE => {
		'meta-spec' => { version => 2 },
		provides => {
			'Regexp::IntInequality' => {
				file => 'lib/Regexp/IntInequality.pm',
				version => '0.90',
			},
		},
		resources => {
			homepage => 'https://github.com/haukex/re-int-ineq',
			repository => {
				type => 'git',
				url  => 'https://github.com/haukex/re-int-ineq.git',
				web  => 'https://github.com/haukex/re-int-ineq',
			},
			bugtracker => {
				web  => 'https://github.com/haukex/re-int-ineq/issues',
			},
		},
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
	},
	PREREQ_PM => {
		'Carp'                   => 0,
		'Exporter'               => '5.58',
	},
	TEST_REQUIRES => {
		'Test::More'             => '1.302096',
		'JSON::PP'               => '2.94',
	},
);
sub MY::postamble {
	return <<'MAKE_FRAG';
.PHONY: authorcover
SHELL = /bin/bash
authorcover:
	cpanm Devel::Cover JSON::MaybeXS
	cover -test
	cover -silent -report json
	# Note Perl Docker images don't have jq installed, so use Perl
	perl -wMstrict -MJSON::PP=decode_json -0777 -ne 'my $$p=decode_json($$_)->{summary}{Total}{total}{percentage}; die "Coverage $$p%\n" unless $$p==100; print "Covage $$p% OK!\n"' cover_db/cover.json
MAKE_FRAG
}
