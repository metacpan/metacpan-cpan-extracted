use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PAR::Dist',
    VERSION_FROM      => 'lib/PAR/Dist.pm', # finds $VERSION
    PREREQ_PM         => {
            'File::Find' => '0',
            'File::Path' => '0',
            'File::Spec' => '0',
            'File::Temp' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PAR/Dist.pm', # retrieve abstract from module
       AUTHOR         => 'Audrey Tang <cpan@audreyt.org>') : ()),
);

