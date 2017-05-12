require 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 'TEI::Lite',
	'AUTHOR'		=> 'D. Hageman <dhageman@dracken.com>',
	'ABSTRACT'		=> 'TEI::Lite document manipulation library',
    'VERSION_FROM'	=> 'Lite.pm',
    'PREREQ_PM'		=> { 'XML::LibXML'			=>	'1.58',
						 'Exporter::Cluster'	=>	0	}
);
