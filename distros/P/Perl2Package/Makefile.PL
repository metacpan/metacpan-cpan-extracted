use 5.008005;
use ExtUtils::MakeMaker 7.12; # for XSMULTI option


WriteMakefile(
  NAME           => 'Perl2Package',
  VERSION_FROM   => 'lib/Perl2Package.pm',
  PREREQ_PM      => {
	'ExtUtils::MakeMaker' => '7.12',
	'Makefile::Parser'=>0,
    'Getopt::Long'=>0,
	'DhMakePerl'=>0,
  },
  ABSTRACT_FROM  => 'lib/Perl2Package.pm',
  ABSTRACT		 => 'Wrapper scripts to generate RPM/DEB packages',
  AUTHOR         => 'Michael Hollenbeck',
  CCFLAGS        => '',
  LIBS			=> '',
  OPTIMIZE       => '-O3',
  LICENSE        => 'OtherLicense',
  XSMULTI        => 1,
  TYPEMAPS		=>["lib/typemap"],
  EXE_FILES		=>["scripts/perl2rpm","scripts/perl2deb"],
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
