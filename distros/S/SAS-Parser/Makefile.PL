require 5.002;
use ExtUtils::MakeMaker;

## PREREQ_PM not implemented well

#--- Installation check
## Makefile.PL for SAS::Parser

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'SAS::Parser',
	DISTNAME => 'SAS-Parser',
    VERSION_FROM => 'lib/SAS/Parser.pm',
    EXE_FILES => ['bin/*'],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	AUTHOR    => 'Michael Friendly (friendly@yorku.ca)',
	ABSTRACT  => 'SAS::Parser - Parse a SAS program file',
    PREREQ_PM => { Text::Balanced => 1.2 },
);
