use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::Mason2Renderer',
    AUTHOR              => q{Alexandre SIMON <asimon@cpan.org>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/Mason2Renderer.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/Mason2Renderer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Mojolicious' => 1.11,
	'Mason' => 2.00,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-Mason2Renderer-*' },
);
