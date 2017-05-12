use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::RedisSubscriber',
    AUTHOR           => q{Binary.com <perl@binary.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/RedisSubscriber.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/RedisSubscriber.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Cache::RedisDB'     => 0,
        'Mojolicious'        => 0,
        'Mojo::EventEmitter' => 0,
        'Mojo::Redis'        => 0,
        'YAML::XS'           => 0, 
        'Try::Tiny'          => 0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-RedisSubscriber-*' },
);
