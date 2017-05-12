use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl6::Attributes',
    VERSION_FROM      => 'lib/Perl6/Attributes.pm', # finds $VERSION
    PREREQ_PM         => { Filter::Simple => 0 },
    ABSTRACT_FROM     => 'lib/Perl6/Attributes.pm', # retrieve abstract from module
    AUTHOR            => 'Luke Palmer <fibonaci@localdomain>',
);
