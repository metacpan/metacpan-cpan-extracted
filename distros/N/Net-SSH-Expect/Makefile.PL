use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SSH::Expect',
    VERSION_FROM      => 'lib/Net/SSH/Expect.pm', # finds $VERSION
    PREREQ_PM         => {'Expect' => '1.14'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SSH/Expect.pod', # retrieve abstract from module
       AUTHOR         => 'Bruno Negrao Guimaraes Zica, <bnegrao@cpan.org>') : ()),
);
