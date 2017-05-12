use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::UniqueTagHelpers',
    AUTHOR           => q{Roman V. Nikolaev <rshadow@rambler.ru>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/UniqueTagHelpers.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/UniqueTagHelpers.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious'       => '5.54',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-XML-UniqueTagHelpers-*' },
    test         => {TESTS => 't/*.t'},
    META_MERGE   => {
        'meta-spec'    => {version => 2},
        dynamic_config => 0,
        resources      => {
            bugtracker => {web => 'https://github.com/rshadow/mojolicious-plugin-unique_tag_helpers/issues'},
            homepage   => 'https://github.com/rshadow/mojolicious-plugin-unique_tag_helpers',
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository => {
                type => 'git',
                url  => 'https://github.com:rshadow/mojolicious-plugin-unique_tag_helpers.git',
                web  => 'https://github.com/rshadow/mojolicious-plugin-unique_tag_helpers',
            },
        },
    },
);
