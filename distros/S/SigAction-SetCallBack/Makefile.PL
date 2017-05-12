use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'SigAction::SetCallBack',
    VERSION_FROM      => 'lib/SigAction/SetCallBack.pm', # finds $VERSION
    PREREQ_PM         => {
           POSIX => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/SigAction/SetCallBack.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Sivirinov') : ()),
);
