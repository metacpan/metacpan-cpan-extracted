use 5.0;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::WWD',
    VERSION_FROM      => 'lib/Net/WWD.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/WWD.pm', # retrieve abstract from module
       AUTHOR         => 'John Baleshiski <john@idserver.org>') : ()),
);
