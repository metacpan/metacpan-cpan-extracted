use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::WWW::Pastebin::Bot::Pastebot::Create',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/WWW/Pastebin/Bot/Pastebot/Create.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                                     => 1.04,
        'POE'                                      => 0.9999,
        'POE::Component::NonBlockingWrapper::Base' => 0.002,
        'WWW::Pastebin::Bot::Pastebot::Create'     => 0.002,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'POE-Component-WWW-Pastebin-Bot-Pastebot-Create-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
