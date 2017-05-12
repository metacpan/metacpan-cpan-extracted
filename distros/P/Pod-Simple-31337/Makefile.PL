use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Pod::Simple::31337',
    'VERSION_FROM'	=> '31337.pm', # finds $VERSION
    'EXE_FILES'     => [ qw[ pod231337 ] ],
    'PREREQ_PM'		=> { Pod::Simple => 0.01, Lingua::31337 => 0.01, Text::Wrap => 98.112902 }, # e.g., Module::Name => 1.1
);
