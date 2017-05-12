use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Plack::Middleware::Dispatch::GP',
    AUTHOR             => q{Alexei Pastuchov <palik@cpan.org>},
    VERSION_FROM       => 'lib/Plack/Middleware/Dispatch/GP.pm',
    ABSTRACT_FROM      => 'lib/Plack/Middleware/Dispatch/GP.pm',
    LICENSE            => 'Artistic_2_0',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 0, },
    BUILD_REQUIRES     => {
        "Test::More"      => "0.98",
        "Test::Exception" => "0.32",
        "Plack::Builder"  => 0,
        "Plack::Test"     => 0,
    },
    PREREQ_PM => {
        "Plack::Middleware"     => 0,
        "Plack::Util::Accessor" => 0,
        "Plack::Request"        => "1.0032",
        "Scalar::Util"          => "1.27",
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Plack-Middleware-Dispatch-*' },
);
