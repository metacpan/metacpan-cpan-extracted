use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Restish::Client',
    license           => 'apache',
    dist_author       => 'Tim H <thend20@pair.com>',
    dist_version_from => 'lib/Restish/Client.pm',
    dist_abstract     => 'A RESTish client...in perl!',

    configure_requires => {
        'Module::Build' => '0.42',
    },

    requires => {
        'perl'                  => '5.008',
        'Moo'                   => '2.000000',
        'Carp'                  => 0,
        'Data::Validate::URI'   => 0,
        'HTTP::Headers'         => 0,
        'HTTP::Request'         => 0,
        'HTTP::Cookies'         => 0,
        'JSON'                  => 0,
        'LWP::UserAgent'        => 0,
        'Text::Sprintf::Named'  => 0,
        'URI::Escape'           => 0,
        'URI::Query'            => 0,
    },

    test_requires => {
        'Test::More'              => '0.88',
        'Test::Exception'         => 0,
        'Test::Mock::LWP::Dispatch' => 0,
    },

    meta_merge => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/thend20/perl-restish-client.git',
                web  => 'https://github.com/thend20/perl-restish-client',
            },
            bugtracker => {
                web => 'https://github.com/thend20/perl-restish-client/issues',
            },
            homepage => 'https://github.com/thend20/perl-restish-client',
        },
        'meta-spec' => { version => 2 },
    },
);

$build->create_build_script;
