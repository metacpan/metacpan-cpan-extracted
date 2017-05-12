use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Parse::Vipar',
    'VERSION_FROM' => 'lib/Parse/Vipar.pm', # finds $VERSION
    'EXE_FILES' => [ 'script/vipar'],
    'PREREQ_PM' => { Tk => 0 },
);

#    'PMLIBDIRS' => ['Parse'],
