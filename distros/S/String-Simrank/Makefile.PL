use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'String::Simrank',
    VERSION_FROM      => 'lib/String/Simrank.pm', # finds $VERSION
    PREREQ_PM         => {Inline => 0.46, Storable => 2.15, Data::Dumper => 2.125, File::Basename => 2.74, IO::File => 1.13, Fcntl => 1.05}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/String/Simrank.pm', # retrieve abstract from module
       AUTHOR         => 'Todd Z. DeSantis <tdesantis@lbl.gov>') : ()),
);
