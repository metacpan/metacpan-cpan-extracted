use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'SQL::Translator::Parser::OpenAPI',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/SQL/Translator/Parser/OpenAPI.pm',
  ABSTRACT_FROM    => 'lib/SQL/Translator/Parser/OpenAPI.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.10',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.98',
    'Test::Snapshot' => '0.02', # better snapshot filenames
  },
  PREREQ_PM => {
    'SQL::Translator' => '0.11024', # 0.11021 gives YAML diffs on "comments"
    'JSON::Validator' => '2.01', # fqn bundle fix
    'String::CamelCase' => '0',
    'SQL::Translator::Schema::Constants' => 0,
    'Lingua::EN::Inflect::Number' => '0',
  },
  clean => { FILES => 'SQL-Translator-Parser-OpenAPI-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/SQL-Translator-Parser-OpenAPI.git',
        web => 'https://github.com/mohawk2/SQL-Translator-Parser-OpenAPI',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/SQL-Translator-Parser-OpenAPI/issues',
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
