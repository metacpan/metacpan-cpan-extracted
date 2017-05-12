use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Component::Log4perl',
    VERSION_FROM      => 'lib/POE/Component/Log4perl.pm', # finds $VERSION
    PREREQ_PM         => {POE => 0,
                          Log::Log4perl => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Component/Log4perl.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin L. Esteb <kesteb@wsipc.org>') : ()),
);
