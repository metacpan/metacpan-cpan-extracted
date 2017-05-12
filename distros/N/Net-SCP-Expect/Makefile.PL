use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Net::SCP::Expect',
    'VERSION_FROM'  => 'Expect.pm', # finds $VERSION
    'PREREQ_PM'     => {'Expect' => '1.14','Term::ReadPassword' => '0.01','Net::IPv6Addr' => '0.2'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Expect.pm', # retrieve abstract from module
       AUTHOR        => 'Eric Rybski <rybskej@yahoo.com>') : ()),
);
