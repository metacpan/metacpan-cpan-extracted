use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PANT',
    'VERSION_FROM'	=> 'PANT.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	XML::Writer=>0, 
	  Carp=>0, 
	  Cwd=>0, 
	  File::Copy=>0, 
	  File::Basename=>0,
	  File::Spec::Functions=>0, 
	  File::Copy::Recursive=>0,
	  File::Compare=>0,
	  Getopt::Long=>0,
	  IO::File=>0, 
	  Exporter=>0, 
	  Archive::Zip=>0,
	  Test::Harness=>0,
	  Test::Harness::Straps=>0,
	  File::Find=>0,
          File::Path=>0,
	  Benchmark=>0,
	  Digest=>0
    	}, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'PANT.pm', # retrieve abstract from module
       AUTHOR     => 'Julian Onions <julianonions@yahoo.nospam.co.uk>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
    'clean'             => { FILES=>"xxx*.html"},
);
