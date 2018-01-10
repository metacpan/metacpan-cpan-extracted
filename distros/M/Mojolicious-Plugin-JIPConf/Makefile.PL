use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %write_makefile_param = (
    NAME             => 'Mojolicious::Plugin::JIPConf',
    AUTHOR           => q{Vladimir Zhavoronkov <flyweight@yandex.ru>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/JIPConf.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/JIPConf.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE       => {
        'meta-spec'    => {version => 2},
        resources      => {
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            bugtracker => {web => 'https://github.com/outtaspace/mojolicious_plugin_jipconf/issues'},
            repository => {
                type => 'git',
                url  => 'https://github.com/outtaspace/mojolicious_plugin_jipconf.git',
                web  => 'https://github.com/outtaspace/mojolicious_plugin_jipconf',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'Test::More'     => 0,
        'English'        => 0,
    },
    PREREQ_PM => {
        'Mojolicious'         => 0,
        'Mojolicious::Plugin' => 0,
        'Mojo::Base'          => 0,
        'JIP::Conf'           => '0.02',
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES => 'Mojolicious-Plugin-JIPConf-*'},
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.63_03); }) {
    $write_makefile_param{PREREQ_PM} = {
        %{ delete $write_makefile_param{'TEST_REQUIRES'} },
        %{ delete $write_makefile_param{'BUILD_REQUIRES'} },
    };
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
    delete $write_makefile_param{'CONFIGURE_REQUIRES'};
}

WriteMakefile(%write_makefile_param);

