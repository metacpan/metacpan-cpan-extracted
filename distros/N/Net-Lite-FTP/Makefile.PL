use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Lite::FTP',
    VERSION_FROM      => 'lib/Net/Lite/FTP.pm', # finds $VERSION
    PREREQ_PM         => { Net::SSLeay::Handle=>0.0, }, # e.g., Module::Name => 1.1
    LICENCE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Lite/FTP.pm', # retrieve abstract from module
       AUTHOR         => 'Dariush Pietrzak <cpan@forumakad.pl>') : ()),
);
