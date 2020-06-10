use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Mojolicious::Command::proxy',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/Mojolicious/Command/proxy.pm',
  ABSTRACT_FROM    => 'lib/Mojolicious/Command/proxy.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => "5.016",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => '6.63_03',
  },
  "PREREQ_PM" => {
    "Mojolicious" => '8.50',
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.92",
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/Mojolicious-Command-proxy.git',
        web => 'https://github.com/mohawk2/Mojolicious-Command-proxy',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/Mojolicious-Command-proxy/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
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
