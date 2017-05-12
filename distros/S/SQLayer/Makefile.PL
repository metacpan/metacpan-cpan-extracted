use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SQLayer',
    'VERSION_FROM' => 'SQLayer.pm', # finds $VERSION
    'PREREQ_PM' => {Carp => 0, 'DBI' => 1.0},
);

