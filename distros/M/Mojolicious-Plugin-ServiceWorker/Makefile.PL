use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::ServiceWorker',
  VERSION_FROM => 'lib/Mojolicious/Plugin/ServiceWorker.pm',
  ABSTRACT_FROM => 'lib/Mojolicious/Plugin/ServiceWorker.pm',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.10',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.98',
  },
  PREREQ_PM => {
    'Mojolicious' => '8.42',
  },
  clean => { FILES => 'Mojolicious-Plugin-ServiceWorker-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/Mojolicious-Plugin-ServiceWorker.git',
        web => 'https://github.com/mohawk2/Mojolicious-Plugin-ServiceWorker',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/Mojolicious-Plugin-ServiceWorker/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod' => '1.22',
          'Pod::Markdown' => 0,
        },
      },
    },
  },
);

sub MY::postamble {
  <<EOF;
pure_all :: README.md

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}
