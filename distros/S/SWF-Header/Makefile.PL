use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'SWF::Header',
    'VERSION_FROM'	=> 'lib/SWF/Header.pm', # finds $VERSION
    'PREREQ_PM'		=> {SWF::BinStream => 0.09}, # e.g., Module::Name => 1.1
);
