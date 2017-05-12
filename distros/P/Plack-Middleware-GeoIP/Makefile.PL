use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Plack::Middleware::GeoIP',
    AUTHOR              => q{Sherwin Daganato <sherwin@daganato.com>},
    VERSION_FROM        => 'lib/Plack/Middleware/GeoIP.pm',
    ABSTRACT_FROM       => 'lib/Plack/Middleware/GeoIP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Plack'         => 0,
        'Geo::IP'       => 1.39,
        'GeoIP2'        => 2.002000,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/sherwind/Plack-Middleware-GeoIP/issues',
            repository  => 'https://github.com/sherwind/Plack-Middleware-GeoIP.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Plack-Middleware-GeoIP-*' },
);
