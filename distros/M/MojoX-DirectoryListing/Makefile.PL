use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MojoX::DirectoryListing',
    AUTHOR           => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM     => 'lib/MojoX/DirectoryListing.pm',
    ABSTRACT_FROM    => 'lib/MojoX/DirectoryListing.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Test::Mojo' => 0,
    },
    PREREQ_PM => {
	'Mojolicious::Lite' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MojoX-DirectoryListing-*' },
);
