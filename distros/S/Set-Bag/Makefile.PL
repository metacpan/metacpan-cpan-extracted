require 5.004;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Set::Bag',
    AUTHOR        => q{David Oswald <davido@cpan.org>},
    VERSION_FROM  => 'Bag.pm',
    ABSTRACT_FROM => 'Bag.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.56',
    },
    BUILD_REQUIRES => {
      'Test::More'    => '0.98',    # A recent version is desirable.
    },
    MIN_PERL_VERSION => '5.004000',
#    PREREQ_PM => {},
    META_MERGE => {
      'resources' => {
        'repository'  => {
          'url'   => 'git://github.com/daoswald/Set-Bag.git',
          'web'   => 'http://github.com/daoswald/Set-Bag',
          'type'  => 'git',
        },
      },
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean     => { FILES => 'Set-Bag-*',       },
);
