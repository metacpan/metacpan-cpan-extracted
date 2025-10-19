use 5.016;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => "Mojolicious::Plugin::FontAwesomeHelpers",
  VERSION_FROM => "lib/Mojolicious/Plugin/FontAwesomeHelpers.pm",
  ABSTRACT     => 'Mojolicious helpers for Font Awesome icons',
  AUTHOR       => 'Delon Newman <delon@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => [qw(t)]},
    prereqs   => {runtime => {requires => {perl => '5.016'}}},
    resources => {
      bugtracker => {web => 'https://github.com/delonnewman/Mojolicious-Plugin-FontAwesomeHelpers/issues'},
      homepage   => 'https://github.com/delonnewman/Mojolicious-Plugin-FontAwesomeHelpers',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/delonnewman/Mojolicious-Plugin-FontAwesomeHelpers.git',
        web  => 'https://github.com/delonnewman/Mojolicious-Plugin-FontAwesomeHelpers',
      },
    },
  },
  PREREQ_PM    => {
    'Mojolicious' => 0,
  },
  test         => {
    TESTS => 't/Mojolicious/Plugin/FontAwesomeHelpers.t'
  }
);
