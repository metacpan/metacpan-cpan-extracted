use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Report::Porf',
    VERSION_FROM      => 'lib/Report/Porf.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Perl Open Report Framework: Fast flexible reports of any format using any input, easy to enhance at runtime',
       AUTHOR         => 'Ralf Peine <ralf.peine@jupiter-programs.de>') : ()),
);
