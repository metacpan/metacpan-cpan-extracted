use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Money::Chinese',
    VERSION_FROM      => 'lib/Money/Chinese.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.006 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Money/Chinese.pm', # retrieve abstract from module
      LICENSE		=> 'Perl',
       AUTHOR         => 'Pan Yu <xiaocong[at]vip.163.com>') : ()),
);
