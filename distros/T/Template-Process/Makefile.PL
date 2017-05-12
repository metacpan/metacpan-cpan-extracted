
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Template::Process',
    VERSION_FROM      => 'lib/Template/Process.pm', 
    PREREQ_PM         => {
      Template        => 0,
      Class::Accessor => 0,
      Carp            => 0,
      Getopt::Long    => 0,
      YAML            => 0,

      Test::More      => 0,

    }, 
    EXE_FILES => [ qw(bin/tt) ],
    PL_FILES => {},
    ($] >= 5.005 ? (
      ABSTRACT_FROM  => 'lib/Template/Process.pm', 
      AUTHOR         => 'Adriano Ferreira <ferreira@cpan.org>',
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
      LICENSE => 'perl',
    ) : ()),
);
