use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'MooX::Attribute::ENV',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/MooX/Attribute/ENV.pm',
  ABSTRACT_FROM    => 'lib/MooX/Attribute/ENV.pm',
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
  clean => { FILES => 'MooX-Attribute-ENV-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#moose',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/moox-attribute-env.git',
        web => 'https://github.com/mohawk2/moox-attribute-env',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/moox-attribute-env/issues',
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
  -d '.git' ? <<EOF : '';
pure_all :: README.md

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}
