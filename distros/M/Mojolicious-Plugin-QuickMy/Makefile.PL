use 5.010001;
 
use strict;
use warnings;
use utf8;
 
use ExtUtils::MakeMaker;
 
WriteMakefile(
  NAME         => 'Mojolicious::Plugin::QuickMy',
  VERSION_FROM => 'lib/Mojolicious/Plugin/QuickMy.pm',
  ABSTRACT     => 'Mojolicious Plugin enables quick and simple access for Mojo::mysql',
  AUTHOR       => 'Pavel Kuptsov <pkuptsov@gmail.com>',
  LICENSE      => 'perl_5',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime => {requires => {perl => '5.010001', "Mojo::mysql" => '0.14', Mojolicious => '6'}}},
    resources      => {
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://bitbucket.org/pkuptsov/mojolicious-plugin-quickmy.git',
        web  => 'https://bitbucket.org/pkuptsov/mojolicious-plugin-quickmy',
      },
    },
  },
  PREREQ_PM => {Mojolicious => '6.0', 'Mojo::mysql' => 0.14},
  test      => {TESTS       => 't/*.t t/*/*.t'}
);