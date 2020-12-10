use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::RoutesAuthDBI',
    AUTHOR           => q{Mikhail Che <mche@cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/RoutesAuthDBI.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/RoutesAuthDBI.pm',
    #~ ABSTRACT_FROM    => 'README.pod',
    LICENSE          =>'Perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious'=>8.67,
        'Mojolicious::Plugin::Authentication'=>1.29,
        'Mojolicious::Plugin::OAuth2::Che'=>1.539,
        'DBI'=>1.6,
        'DBIx::Mojo::Template'=>0.05,
        'Hash::Merge'=>0.200,
    },
    META_MERGE => {
      'meta-spec' => { version => 2 },
      homepage   => 'https://github.com/mche',
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI.git',
          web => 'https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #~ clean => { FILES => 'Mojolicious-Plugin-RoutesAuthDBI-*' },
);
