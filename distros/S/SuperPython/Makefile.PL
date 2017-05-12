use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SuperPython',
    'VERSION_FROM'	=> 'SuperPython.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Filter::Simple' => 0.50}, # e.g., Module::Name => 1.1
);
