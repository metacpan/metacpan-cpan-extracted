use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::PwithBR',
    VERSION_FROM      => 'lib/Template/Plugin/PwithBR.pm', # finds $VERSION
    PREREQ_PM         => { Template => 2.14 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/PwithBR.pm', # retrieve abstract from module
       AUTHOR         => 'Daisuke Komatsu <komatsu@taro-web.com)>') : ()),
);
