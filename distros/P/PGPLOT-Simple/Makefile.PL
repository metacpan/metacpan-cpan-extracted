use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PGPLOT::Simple',
    VERSION_FROM      => 'lib/PGPLOT/Simple.pm', # finds $VERSION
    PREREQ_PM         => {
        PGPLOT          =>  "2.18", 
        Carp            =>       0,
        List::Util      =>       0,
        List::MoreUtils =>       0,
        Scalar::Util    =>       0,
    }, # e.g., Module::Name => 1.1
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PGPLOT/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Florian Merges <fmerges@cpan.org>') : ()),
);
