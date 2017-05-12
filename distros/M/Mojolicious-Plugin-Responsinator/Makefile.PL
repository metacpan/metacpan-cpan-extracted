use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Mojolicious::Plugin::Responsinator',
  ABSTRACT_FROM => 'lib/Mojolicious/Plugin/Responsinator.pm',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Responsinator.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Mojolicious' => '4.87',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.90',
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/Mojolicious-Plugin-Responsinator',
      bugtracker => 'https://github.com/jhthorsen/mojolicious-plugin-responsinator/issues',
      repository => 'https://github.com/jhthorsen/mojolicious-plugin-responsinator.git',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
