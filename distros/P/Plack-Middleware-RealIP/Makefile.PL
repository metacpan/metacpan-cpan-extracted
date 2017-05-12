use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Plack::Middleware::RealIP',
    AUTHOR              => q{Sherwin Daganato <sherwin@daganato.com>},
    VERSION_FROM        => 'lib/Plack/Middleware/RealIP.pm',
    ABSTRACT_FROM       => 'lib/Plack/Middleware/RealIP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Plack'         => 0,
        'Net::Netmask'  => 0,
    },
    MIN_PERL_VERSION    => '5.008',
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/sherwind/Plack-Middleware-RealIP/issues',
            repository  => 'https://github.com/sherwind/Plack-Middleware-RealIP.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Plack-Middleware-RealIP-*' },
);
