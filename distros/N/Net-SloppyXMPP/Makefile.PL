use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SloppyXMPP',
    VERSION_FROM      => 'lib/Net/SloppyXMPP.pm', # finds $VERSION
    PREREQ_PM         =>  {
                            XML::Simple => 0,
                            Data::Dumper => 0,
                            IO::Socket::INET => 0,
                            Encode => 0,
                          }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SloppyXMPP.pm', # retrieve abstract from module
       AUTHOR         => 'Dusty Wilson <dusty_-_at_-_megagram_-_com>') : ()),
);
