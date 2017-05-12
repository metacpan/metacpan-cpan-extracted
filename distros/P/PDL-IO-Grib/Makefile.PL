use ExtUtils::MakeMaker;

WriteMakefile(
				  NAME => 'PDL::IO::Grib',
				  EXE_FILES => 'GribView.pl',
				  VERSION_FROM => 'Grib.pm',
				  DIR => 'Grib',
				  dist => {COMPRESS => 'gzip', SUFFIX=> 'gz'}
);
