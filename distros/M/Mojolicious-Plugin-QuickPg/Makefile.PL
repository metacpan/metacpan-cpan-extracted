use 5.010001;
 
use strict;
use warnings;
use utf8;
 
use ExtUtils::MakeMaker;
 
WriteMakefile(
  NAME         => 'Mojolicious::Plugin::QuickPg',
  VERSION_FROM => 'lib/Mojolicious/Plugin/QuickPg.pm',
  ABSTRACT     => 'Mojolicious Plugin enables quick and simple access for Mojo::Pg',
  AUTHOR       => 'Pavel Kuptsov <pkuptsov@gmail.com>',
  LICENSE      => 'perl_5',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime => {requires => {perl => '5.010001', "Mojo::Pg" => '2', Mojolicious => '6'}}},
    resources      => {
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://bitbucket.org/pkuptsov/mojolicious-plugin-quickpg.git',
        web  => 'https://bitbucket.org/pkuptsov/mojolicious-plugin-quickpg',
      },
    },
  },
  PREREQ_PM => {Mojolicious => '6.0', 'Mojo::Pg' => 2.0},
  test      => {TESTS       => 't/*.t t/*/*.t'}
);