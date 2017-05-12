use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Pg::Simple',
    'VERSION_FROM' => 'Simple.pm', # finds $VERSION
    'PREREQ_PM' => { Pg => 0 },
);
