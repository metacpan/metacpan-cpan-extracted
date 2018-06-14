use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::StaticShare',
  VERSION_FROM => 'lib/Mojolicious/Plugin/StaticShare.pm',
  ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/StaticShare.pm',
  LICENSE => 'perl_5',
  AUTHOR       => q{Михаил Че (Mikhail Che) <mche[-at-]cpan.org>},
  PL_FILES         => {},
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  BUILD_REQUIRES => {
      'Test::More' => '0',
  },
  PREREQ_PM    => {
    'Mojolicious' => '7.36',
    'HTTP::AcceptLanguage'=>'0.02',
    'Time::Piece'=>'1.31',
    #~ Text::Markdown::Hoedown if markdown
  },
  #~ test         => {TESTS => 't/*.t'},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/mche/Mojolicious-Plugin-StaticShare.git',
        web => 'https://github.com/mche/Mojolicious-Plugin-StaticShare',
      },
    },
  },
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  #~ clean => { FILES => 'Mojolicious-Plugin-StaticShare-*' },
);
