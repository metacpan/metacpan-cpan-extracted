use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::YamlRoutes',
  VERSION_FROM => 'lib/Mojolicious/Plugin/YamlRoutes.pm',
  AUTHOR       => 'HDP <hdp@djmania.es>',
  PREREQ_PM    => {'Mojolicious' => '8.71','YAML::XS' => '0.83'},
  test         => {TESTS => 't/*.t'}
);
