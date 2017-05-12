use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Protocol::Simple',
    VERSION_FROM      => 'lib/Net/Protocol/Simple.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Protocol/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Wes Young <saxguard9-cpan@yahoo.com>') : ()),
);
