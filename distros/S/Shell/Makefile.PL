
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
  NAME           => 'Shell',
  VERSION_FROM   => 'Shell.pm',
  INSTALLDIRS    => ($] >= 5.011 ? 'site' : 'perl'),
  PREREQ_PM      => {
    'Test::More' => 0,
  },
  ($] >= 5.005 ? (
    ABSTRACT_FROM => 'Shell.pm',
  ) : ()),
  ($EUMM_VERSION >= 6.31 ? (
    LICENSE => 'perl', 
  ) :()),
  ($EUMM_VERSION > 6.4501 ? (
    META_MERGE => {
      resources => {
        repository => 'http://github.com/aferreira/cpan-Shell',
      }
    },
  ) : ()),

);
