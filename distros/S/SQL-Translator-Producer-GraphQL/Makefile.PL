use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'SQL::Translator::Producer::GraphQL',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/SQL/Translator/Producer/GraphQL.pm',
  ABSTRACT_FROM    => 'lib/SQL/Translator/Producer/GraphQL.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.98',
    'Test::Snapshot' => '0.05',
  },
  PREREQ_PM => {
    'SQL::Translator' => '0',
    'GraphQL' => '0.21', # DateTime
    'GraphQL::Plugin::Convert::DBIC' => '0.07', # singular not plural
  },
  clean => { FILES => 'SQL-Translator-Producer-GraphQL-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:graphql-perl/SQL-Translator-Producer-GraphQL.git',
        web => 'https://github.com/graphql-perl/SQL-Translator-Producer-GraphQL',
      },
      bugtracker  => {
        web => 'https://github.com/graphql-perl/SQL-Translator-Producer-GraphQL/issues',
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

README.md : lib/SQL/Translator/Producer/GraphQL.pm
\tpod2markdown \$< >\$\@
EOF
}
