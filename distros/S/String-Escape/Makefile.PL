use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Escape',
    AUTHOR              => q{Matthew Simon Cavalletto <simonm@cavalletto.org>},
    VERSION_FROM        => 'Escape.pm',
    ABSTRACT_FROM       => 'Escape.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
    	? ('LICENSE'=> 'perl')
    	: ()
	),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Escape-*' },
);

sub MY::postamble { <<'<<' }

everything: FORCE
	make again; make reltest; make disttest

again: FORCE
	make makefile; make cleanmanifest

makefile: FORCE
	make clean; perl Makefile.PL; make pm_to_blib

cleanmanifest: FORCE
	rm MANIFEST; touch MANIFEST; make manifest

reltest: FORCE
	RELEASE_TESTING=1 make test

%.t: pm_to_blib FORCE
	perl -Iblib/lib -w $@

cover: FORCE
	cover -delete; cover -test; open cover_db/coverage.html

<<

1;