use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Proc::Branch',
    VERSION_FROM      => 'lib/Proc/Branch.pm',
    PREREQ_PM         => {},
    ( $] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Proc/Branch.pm', # retrieve abstract from module
       AUTHOR         => 'In Suk Joung') : ()),
);
