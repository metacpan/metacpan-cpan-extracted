use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::Auth::Simple',
    AUTHOR              => q{Kim Hawtin <kim@hawtin.net.au>},
    VERSION_FROM        => 'lib/MojoX/Auth/Simple.pm',
    ABSTRACT_FROM       => 'lib/MojoX/Auth/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'MojoX::Session' => 0,
        'Mojo'           => 0.999914,
        'Test::More'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX-Auth-Simple-*' },
);
