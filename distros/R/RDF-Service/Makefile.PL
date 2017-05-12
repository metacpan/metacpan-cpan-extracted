# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

BEGIN { require 5.006 }
use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'RDF::Service',
	      'PMLIBDIRS'    => [ 'lib' ],
 	      'VERSION_FROM' => 'lib/RDF/Service.pm', # finds $VERSION
	      'EXE_FILES'    => [ 'cgi-bin/client.cgi',
				  'cgi-bin/tail.cgi', 'bin/serv1.pl'  ],
 	      'PREREQ_PM'     =>
	      {
		  'DBI'          => 0,
		  'URI'          => 0,
		  'Time::HiRes'  => 0,
		  'Template'     => 2,
		  'CGI'          => 0,
		  'IO::Socket'   => 1.18,
		  'Data::Dumper' => 0,
		  'FreezeThaw'   => 0,
	      },
	      'dist'          =>
	      {
		  'COMPRESS' => 'gzip',
		  'SUFFIX'   => 'gz',
	      }
);
