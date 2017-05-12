use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Module::Build::Prereq',
    VERSION_FROM      => 'lib/Module/Build/Prereq.pm',
    PREREQ_PM         => {
                          'Module::CoreList' => '0',
                          'File::Find' => '0' },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Module/Build/Prereq.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Wiersdorf <scott@betterservers.com>') : ()),
);
