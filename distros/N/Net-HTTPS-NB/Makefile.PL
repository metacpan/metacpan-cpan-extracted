use 5.005000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::HTTPS::NB',
    LICENSE           => 'perl',
    VERSION_FROM      => 'lib/Net/HTTPS/NB.pm', # finds $VERSION
    PREREQ_PM         => { Exporter => 0, IO::Socket::SSL => 0.98, Net::HTTP => 0, Net::HTTPS => 0, Test::More => 0.88 },
    META_MERGE        => { resources => {repository => 'https://github.com/olegwtf/p5-Net-HTTPS-NB'} },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/HTTPS/NB.pm', # retrieve abstract from module
       AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
