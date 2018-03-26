use 5.020000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $module_file = 'lib/Mojolicious/Command/generate/resources.pm';
my $preop       = qq'pod2text $module_file > README;'
  . qq'pod2markdown $module_file > README.md';
WriteMakefile(
  NAME          => 'Mojolicious::Command::generate::resources',
  VERSION_FROM  => $module_file,                               # finds \$VERSION
  AUTHOR        => 'Красимир Беров (berov@cpan.org)',
  ABSTRACT_FROM => $module_file,
  PREREQ_PM => {'Mojolicious' => '7.60', perl => '5.020001'},
  TEST_REQUIRES =>
    {'Mojo::SQLite' => '3.000', 'Mojolicious::Plugin::OpenAPI' => '1.25'},
  test       => {TESTS => 't/*.t'},
  clean      => {FILES => 'Mojolicious-Command-*'},
  dist       => {PREOP => $preop},
  META_MERGE => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime => {requires => {perl => '5.020001'}}},
    resources      => {
      bugtracker => {
        web =>
          'https://github.com/kberov/Mojolicious-Command-generate-resources/issues'
      },
      homepage =>
        'https://github.com/kberov/Mojolicious-Command-generate-resources',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url =>
          'https://github.com/kberov/Mojolicious-Command-generate-resources.git',
        web =>
          'https://github.com/kberov/Mojolicious-Command-generate-resources',
      },
    },
  },
);
