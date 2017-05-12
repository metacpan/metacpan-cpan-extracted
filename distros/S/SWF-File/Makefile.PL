use ExtUtils::MakeMaker;
require 5.006;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SWF::File',
    'VERSION_FROM' => 'lib/SWF/Element.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Data::TemporaryBag' => 0.08,
	'Compress::Zlib'     => 0,
	},
    'EXE_FILES' => ['dumpswf.plx'],
);

