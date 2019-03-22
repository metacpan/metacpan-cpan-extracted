use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'MooX::StrictHas',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/MooX/StrictHas.pm',
  ABSTRACT_FROM    => 'lib/MooX/StrictHas.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.008',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
  },
  PREREQ_PM => {
    'Moo' => '0',
  },
  clean => { FILES => 'MooX-StrictHas-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#moose',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/moox-stricthas.git',
        web => 'https://github.com/mohawk2/moox-stricthas',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/moox-stricthas/issues',
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
