use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SimpleXlsx',
    VERSION_FROM      => 'lib/SimpleXlsx.pm', # finds $VERSION
    PREREQ_PM         => {'Archive::Zip' => '1.30', 'XML::Simple' => '2.18', 'File::Basename' => '2.78'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SimpleXlsx.pm', # retrieve abstract from module
       AUTHOR         => 'Joe Estock <jestock@nutextonline.com>') : ()),
);
