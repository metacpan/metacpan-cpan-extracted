use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Twitch::Oauth2',
    license             => 'perl',
    dist_abstract       => 'Net::Twitch::Oauth2 wrapper for Twitch.tv OAuth2',
    dist_author         => 'Ronald Reed <rjreed67@gmail.com>',
    requires => {
        'LWP::UserAgent' => '0',
        'JSON::Any' => '0',
        'URI' => '0',
        'URI::Escape' => '0',
        'Carp' => '0',
    },
    build_requires => {
        'Test::More' => '0.10',
        'Test::Exception' => '0',
        'Test::MockObject' => '0',
        'Test::MockModule' => '0',
    },
);

$builder->create_build_script();
