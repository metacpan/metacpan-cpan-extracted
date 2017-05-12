use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MojoX::Plugin::PHP',
    AUTHOR           => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM     => 'lib/MojoX/Plugin/PHP.pm',
    ABSTRACT_FROM    => 'lib/MojoX/Plugin/PHP.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'File::Spec::Functions' => 0,
	'File::Temp' => 0,
	'File::Tools' => 0,
	Mojolicious => 4.0,
	PHP => 0.15,
	'Sys::Hostname' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MojoX-Plugin-PHP-*' },
);
