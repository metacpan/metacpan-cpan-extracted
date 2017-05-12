use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Plucene::Analysis::UTF8Analyzer',
    VERSION_FROM      => 'lib/Plucene/Analysis/UTF8Analyzer.pm', # finds $VERSION
    PREREQ_PM         => {'Plucene' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Plucene/Analysis/UTF8Analyzer.pm', # retrieve abstract from module
       AUTHOR         => 'Gea-Suan Lin <gslin@gslin.org>') : ()),
);
