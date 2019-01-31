use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::Minion::Workers',
    AUTHOR           => q{Михаил Че (Mikhail Che) <mche[-at-]cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/Minion/Workers.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/Minion/Workers.pm',
    LICENSE          => 'Perl',
    PL_FILES         => {},
    #~ MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Mojolicious'=>8.00,
        'Minion'=>'9.07',
    },
    META_MERGE => {
      'meta-spec' => { version => 2 },
      homepage   => 'https://github.com/mche',
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/mche/Mojolicious-Plugin-Minion-Workers.git',
          web => 'https://github.com/mche/Mojolicious-Plugin-Minion-Workers',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #~ clean => { FILES => 'Mojolicious-Plugin-Minion-Workers-*' },
);
