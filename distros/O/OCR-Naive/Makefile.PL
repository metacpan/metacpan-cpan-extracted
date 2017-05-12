# $Id: Makefile.PL,v 1.2 2007/08/21 11:37:04 dk Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'OCR::Naive',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'Naive.pm',
	VERSION_FROM  => 'Naive.pm',
	PREREQ_PM     => { Prima => 0, IPA => 0 },
	EXE_FILES     => ['bin/ocr', 'bin/makedict'],
);
