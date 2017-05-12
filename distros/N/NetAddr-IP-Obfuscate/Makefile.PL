use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'NetAddr::IP::Obfuscate',
    VERSION_FROM      => 'lib/NetAddr/IP/Obfuscate.pm', # finds $VERSION
    PREREQ_PM         => { NetAddr::IP::Find => 0.03 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Doug Maxwell <doug@turinglabs.com>') : ()),
);
