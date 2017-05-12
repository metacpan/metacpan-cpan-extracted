use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Canopy::BAM',
    VERSION_FROM      => 'lib/Net/Canopy/BAM.pm', # finds $VERSION
    PREREQ_PM         => {'Bit::Vector' => 7.1, 'Data::Dumper' => 0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Canopy/BAM.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Auer <jda@tapodi.net>') : ()),
);
