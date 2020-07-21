use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::WebPush',
  VERSION_FROM => 'lib/Mojolicious/Plugin/WebPush.pm',
  ABSTRACT_FROM => 'lib/Mojolicious/Plugin/WebPush.pm',
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
    'Crypt::JWT' => '0.026',
    'CryptX' => '0.068',
    'Crypt::RFC8188' => '0.01',
    'Mojolicious::Plugin::ServiceWorker' => '0.02', # listeners
  },
  clean => { FILES => 'Mojolicious-Plugin-WebPush-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/Mojolicious-Plugin-WebPush.git',
        web => 'https://github.com/mohawk2/Mojolicious-Plugin-WebPush',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/Mojolicious-Plugin-WebPush/issues',
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
