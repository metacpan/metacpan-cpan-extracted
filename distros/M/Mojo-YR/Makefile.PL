use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Mojo::YR',
  ABSTRACT_FROM => 'lib/Mojo/YR.pm',
  VERSION_FROM => 'lib/Mojo/YR.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Mojolicious' => '4.30',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.90',
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/Mojo-YR',
      bugtracker => 'https://github.com/jhthorsen/mojo-yr/issues',
      repository => 'https://github.com/jhthorsen/mojo-yr.git',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
