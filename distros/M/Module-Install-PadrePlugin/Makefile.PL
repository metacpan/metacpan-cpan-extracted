use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Module::Install::PadrePlugin',
    VERSION_FROM      => 'lib/Module/Install/PadrePlugin.pm', # finds $VERSION
    PREREQ_PM         => {
      'inc::Module::Install' => '0.77',
      'PAR::Dist' => '0.17',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Module/Install/PadrePlugin.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : (),
       LICENSE => 'perl'),
);
