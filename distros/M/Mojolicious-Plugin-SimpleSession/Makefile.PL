use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::SimpleSession',
    AUTHOR              => q{Justin Hawkins <justin@cpan.org>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/SimpleSession.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/SimpleSession.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Mojo' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-SimpleSession-*' },
);
