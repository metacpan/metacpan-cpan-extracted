use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Model3D::Poser::GetStringRes',
    VERSION_FROM      => 'lib/Model3D/Poser/GetStringRes.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Model3D/Poser/GetStringRes.pm', # retrieve abstract from module
       AUTHOR         => 'Dodger <dodger@whatever3d.com>') : ()),
);
