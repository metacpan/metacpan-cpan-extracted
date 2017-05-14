use strict;
use ExtUtils::MakeMaker;

print <<END;



  You MUST create and initialize a MyLibrary database before you
  can install this module. If you don't, then the tests WILL fail.

  See the INSTALL file for details. It's not hard. Really!



END

&WriteMakefile(

	NAME		 => 'MyLibrary',
	DISTNAME	 => 'MyLibrary',
	VERSION_FROM => 'lib/MyLibrary/Core.pm',
	ABSTRACT	 => 'MyLibrary - a true digital library framework and toolbox',
	PMLIBDIRS	 => [ qw( lib/ ) ],
	AUTHOR		 => 'Eric Lease Morgan and Rob Fox',
	PREREQ_PM	 => { 
						'Test::More'   => 0,
						'CGI::Session' => 0,
						'Carp'         => 0,
						'DBI'          => '1.43'
                    },
	dist 		 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	depend		 => { Makefile => '$(VERSION_FROM)' }
	
);

