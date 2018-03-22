use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::BasicAuthPlus',
    AUTHOR              => q{Brad Robertson <blr@cpan.org>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/BasicAuthPlus.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/BasicAuthPlus.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    MIN_PERL_VERSION => '5.006001',
    BUILD_REQUIRES      => {
        'Mojo::IOLoop' => 0,
        'Test::More'   => 0,
        'Test::Mojo'   => 0,
        'Mojo::ByteStream' => 0,
        'Mojolicious::Lite' => 0,
    },
    META_MERGE          => {
        resources => {
            repository  =>
            'http://github.com/stregone/mojolicious-plugin-basicauthplus',
            bugtracker  =>
            'http://github.com/stregone/mojolicious-plugin-basicauthplus/issues'
        }
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'Mojolicious' => '1.4',
        'Authen::Simple::Password' => 0,
        'Authen::Simple::Passwd' => 0,
        'Net::LDAP' => 0,
    },
    EXE_FILES => ['examples/sample.pl'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-BasicAuthPlus-*' },
);
