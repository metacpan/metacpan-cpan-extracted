use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Server::Mail::ESMTP::STARTTLS',
    license             => 'perl',
    dist_author         => 'Dan Moore <dan@moore.cx>',
    dist_version_from   => 'lib/Net/Server/Mail/ESMTP/STARTTLS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Net::Server::Mail::ESMTP::Extension' => 0,
        'IO::Socket::SSL' => 0, 
    },
    add_to_cleanup      => [ 'Net-Server-Mail-ESMTP-STARTTLS-*' ],
    create_makefile_pl => 'traditional',
    meta_add => {
        resources => {
            repository => 'git://github.com/mgrdcm/net-server-mail-esmtp-starttls.git',
        },
    },

);

$builder->create_build_script();
