use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Mojolicious::Command::bulkget',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/Mojolicious/Command/bulkget.pm',
  ABSTRACT_FROM    => 'lib/Mojolicious/Command/bulkget.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => "5.006",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => '6.63_03',
  },
  "PREREQ_PM" => {
    "Mojolicious" => '7.48', # promises
  },
  "TEST_REQUIRES" => {
    "Mojolicious" => '7.48', # promises
    "Test::More" => "0.92",
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:graphql-perl/Mojolicious-Command-bulkget.git',
        web => 'https://github.com/graphql-perl/Mojolicious-Command-bulkget',
      },
      bugtracker  => {
        web => 'https://github.com/graphql-perl/Mojolicious-Command-bulkget/issues',
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

README.md : lib/Mojolicious/Command/bulkget.pm
\tpod2markdown \$< >\$\@
EOF
}
