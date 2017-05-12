#use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Object::Hybrid',
    VERSION_FROM      => 'lib/Object/Hybrid.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Object/Hybrid.pm', # retrieve abstract from module
       AUTHOR         => 'Alexandr Kononoff <parsels@mail.ru>') : ()),
    PL_FILES => {}, # so that MakeMaker doesn't try to run your Build.PL as a normal .PL file
    
);
