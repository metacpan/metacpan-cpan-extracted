use ExtUtils::MakeMaker;
use DBIx::Password;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Slash::Gallery',
    'VERSION_FROM' => 'Gallery.pm', # finds $VERSION
    'PREREQ_PM' => { 'Image::Info' => 1.00, 'Imager' => 0.30 },
    'PM'	=> { 'Gallery.pm' => '$(INST_LIBDIR)/Gallery.pm' },
);

