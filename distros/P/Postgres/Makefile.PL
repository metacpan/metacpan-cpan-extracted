use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Postgres',
	      'VERSION_FROM' => 'Postgres.pm', # finds $VERSION
	      'LIBS'	=> ['-L/usr/local/postgres95/lib -lpq'],
	      'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
	      'INC'	=> '-I/usr/local/postgres95/include',
              dist => {
                       SUFFIX => 'gz',
                       COMPRESS => 'gzip -9',
                      },
);
