use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SWF::Builder',
    'VERSION_FROM' => 'lib/SWF/Builder.pm', # finds $VERSION
    'PREREQ_PM' => {
        'Compress::Zlib'  => 0,
	'SWF::BinStream'  => 0,
	'SWF::File'       => 0,
	'SWF::Parser'     => 0,
	'SWF::Element'    => 0.41,
#	'Font::TTF::Ttc'  => 0,
#	'Font::TTF::Font' => 0.34,
#	'Font::FreeType' => 0,
#	'Math::Bezier::Convert' => 0,
    },
    'EXE_FILES' => ['scripts/asc.plx'],
);
