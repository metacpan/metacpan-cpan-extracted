use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Schedule::TableImage',
    'VERSION_FROM' => 'TableImage.pm', # finds $VERSION
    'PREREQ_PM'    => { Image::Magick => 5.47, Text::Wrapper =>1.000  }, # e.g., Module::Name => 1.1
	      
);
