use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'ScriptUtil',
    VERSION_FROM      => 'lib/ScriptUtil.pm', # finds $VERSION
    PREREQ_PM         => { Fcntl => 0, Carp => 1.0, Moose => 0.93, File::Log => 1.05, Archive::Zip => 1.30, PathTools => 3.31 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ScriptUtil.pm', # retrieve abstract from module
       AUTHOR         => 'Cameron Stuart <cam@asoftware.net.au>') : ()),
);
