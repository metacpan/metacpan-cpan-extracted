use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'POE::Wheel::Spawner',
    AUTHOR             => q{Alexei Pastuchov E<lt>palik at cpan.orgE<gt>.},
    VERSION_FROM       => "lib/POE/Wheel/Spawner.pm",
    ABSTRACT_FROM      => "lib/POE/Wheel/Spawner.pm",
    LICENSE            => "perl",
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 0, },
    BUILD_REQUIRES     => { "Test::More" => 0, },
    PREREQ_PM          => {
        "POE::Filter::Reference" => 0,
        "POE::Kernel"            => 0,
        "POE::Session"           => 0,
        "POE::Wheel::Run"        => 0,
        "fields"                 => 0,
        "version"                => "0.77",
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            bugtracker =>
                { web => "https://github.com/p-alik/POE-Wheel-Spawner/issues" },
            repository => {
                type => "git",
                url  => "https://github.com/p-alik/POE-Wheel-Spawner.git",
                web  => "https://github.com/p-alik/POE-Wheel-Spawner",
            },
        },
    },
    dist  => { COMPRESS => "gzip -9f", SUFFIX => "gz", },
    clean => { FILES    => "POE-Wheel-Spawner-*" },
);
