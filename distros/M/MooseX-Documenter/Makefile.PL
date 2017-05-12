use 5.008000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME         => 'MooseX::Documenter',
  VERSION_FROM => 'lib/MooseX/Documenter.pm',    # finds $VERSION
  PREREQ_PM    => {
    'Moose'                     => 0,
    'PPI::Document'             => 0,
    'Test::More'                => 0,
    'Test::MockObject::Extends' => 0,
    'Test::Exception'           => 0
  },                                             # e.g., Module::Name => 1.1
  INSTALLDIRS => 'site',
  (
    $] >= 5.005
    ?    ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM =>
        'lib/MooseX/Documenter.pm',    # retrieve abstract from module
      AUTHOR => 'David Bury <dsbike@gmail.com>'
      )
    : ()
  ),
);
