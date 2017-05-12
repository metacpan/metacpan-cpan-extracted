
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'TeX::DVI',
	'VERSION_FROM'	=> 'lib/TeX/DVI/Parse.pm',
	'PREREQ_PM'	=> { 'Font::TFM' => '0.100', },
	'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	'clean'		=> { FILES => 't/texput1.out t/texput2.out t/parse.out' },
	);
