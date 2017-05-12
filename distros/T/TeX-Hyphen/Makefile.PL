
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'TeX::Hyphen',
	DISTNAME	=> 'TeX-Hyphen',
	VERSION_FROM	=> 'lib/TeX/Hyphen.pm',
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	'clean'         => { FILES => 'testhyp.hyp' },
	);
