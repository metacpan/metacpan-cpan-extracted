use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'RPM::VersionSort',
    'VERSION_FROM' => 'VersionSort.pm', # finds $VERSION
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
);
