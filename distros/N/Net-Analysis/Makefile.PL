use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Analysis',
    VERSION_FROM      => 'lib/Net/Analysis.pm', # finds $VERSION
    #PREREQ_PRINT      => 1,
    PREREQ_PM         => {'Net::Pcap' => 0,
                          'NetPacket' => 0,
                          'Params::Validate' => 0,
                          'Test::MockObject' => 0,
                          'LWP' => 0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Analysis.pm', # retrieve abstract from module
       AUTHOR         => 'A. B. Worrall <worrall@cpan.org>') : ()),
);
