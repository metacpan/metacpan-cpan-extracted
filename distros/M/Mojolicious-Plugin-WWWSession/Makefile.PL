use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::WWWSession',
    AUTHOR              => q{Gligan Calin Horea <gliganh@gmail.com>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/WWWSession.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/WWWSession.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Mojolicious::Plugin' => 0,
		'WWW::Session' => 0.08,
		'Digest::MD5' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-WWWSession-*' },
);
