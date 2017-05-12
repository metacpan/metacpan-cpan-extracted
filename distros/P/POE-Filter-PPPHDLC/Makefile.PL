use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Filter::PPPHDLC',
    VERSION_FROM      => 'lib/POE/Filter/PPPHDLC.pm', # finds $VERSION
    PREREQ_PM         => {'Test::More'  =>  0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/POE/Filter/PPPHDLC.pm', # retrieve abstract from module
    AUTHOR            => 'Benjamin Smith <bsmith@cpan.org>',
);
