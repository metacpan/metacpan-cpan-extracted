use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::Mason1Renderer',
    AUTHOR              => q{Alexandre SIMON <asimon@cpan.org>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/Mason1Renderer.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/Mason1Renderer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Mojolicious' => 1.11,
	'HTML::Mason' => 1.30,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-Mason1Renderer-*' },
);
