use 5.020;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'PrivatusAnalytics',
    AUTHOR             => 'Two Phase LLC <james@privatusanalytics.com>',
    VERSION_FROM       => 'lib/PrivatusAnalytics.pm',
    ABSTRACT_FROM      => 'lib/PrivatusAnalytics.pm',
    LICENSE            => 'mit',
    MIN_PERL_VERSION   => '5.020',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
    PREREQ_PM          => {
        'B'            => 0,
        'Carp'         => 0,
        'Exporter'     => '5.57',
        'JSON::PP'     => '2.27',
        'Scalar::Util' => 0,
    },
    TEST_REQUIRES => { 'Test::More' => '0.96' },
    META_MERGE    => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            homepage   => 'https://privatusanalytics.com',
            license    => ['https://opensource.org/licenses/MIT'],
            bugtracker => { web => 'https://github.com/Privatus-Analytics/perl/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/Privatus-Analytics/perl.git',
                web  => 'https://github.com/Privatus-Analytics/perl',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    'Mojolicious' => '9.0',
                    'Dancer2'     => '0.400000',
                    'Plack'       => '1.0047',
                },
            },
            test => {
                recommends => {
                    'Mojolicious'           => '9.0',
                    'Dancer2'               => '0.400000',
                    'Plack'                 => '1.0047',
                    'HTTP::Request::Common' => 0,
                },
            },
            develop => {
                requires => {
                    'Perl::Critic' => 0,
                    'Perl::Tidy'   => 0,
                },
            },
        },
        provides => {
            'PrivatusAnalytics'             => { file => 'lib/PrivatusAnalytics.pm',            version => '1.0.0' },
            'PrivatusAnalytics::Attributes' => { file => 'lib/PrivatusAnalytics/Attributes.pm', version => '1.0.0' },
            'PrivatusAnalytics::PageProps'  => { file => 'lib/PrivatusAnalytics/PageProps.pm',  version => '1.0.0' },
            'Mojolicious::Plugin::PrivatusAnalytics' =>
              { file => 'lib/Mojolicious/Plugin/PrivatusAnalytics.pm', version => '1.0.0' },
            'Dancer2::Plugin::PrivatusAnalytics' =>
              { file => 'lib/Dancer2/Plugin/PrivatusAnalytics.pm', version => '1.0.0' },
            'Plack::Middleware::PrivatusAnalytics' =>
              { file => 'lib/Plack/Middleware/PrivatusAnalytics.pm', version => '1.0.0' },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PrivatusAnalytics-*' },
);
