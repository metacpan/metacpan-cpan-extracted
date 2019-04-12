use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'SQL::Abstract::Prefetch',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/SQL/Abstract/Prefetch.pm',
  ABSTRACT_FROM    => 'lib/SQL/Abstract/Prefetch.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.010001',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.94', # subtest
    'DBD::SQLite' => '1.62',
  },
  PREREQ_PM => {
    'Mojo::Base' => '0',
    'Lingua::EN::Inflect::Number' => '0',
    'Scalar::Util' => '0',
    'DBI' => 0,
    'SQL::Abstract::Pg' => 0,
  },
  clean => { FILES => 'SQL-Abstract-Prefetch-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#dbix-class',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/SQL-Abstract-Prefetch.git',
        web => 'https://github.com/mohawk2/SQL-Abstract-Prefetch',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/SQL-Abstract-Prefetch/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod::Coverage' => '1.08',
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
