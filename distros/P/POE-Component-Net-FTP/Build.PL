use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::Net::FTP',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/Net/FTP.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                                     => 1.04,
        'POE'                                      => 0.9999,
        'Net::FTP'                                 => 2.77,
        'POE::Component::NonBlockingWrapper::Base' => 0.002,
    },
    add_to_cleanup      => [ 'POE-Component-Net-FTP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
