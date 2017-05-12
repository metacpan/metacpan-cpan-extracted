use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'P4::Server',
    license             => 'perl',
    dist_author         => 'Stephen Vance <steve@vance.com>',
    dist_version_from   => 'lib/P4/Server.pm',
    build_requires      => {
        'Module::Locate'    => 0,
        'Test::More'        => 0,
    },
    requires            => {
        'Error::Exception'  => 0,
        'IO::Select'        => 0,
        'IO::Socket'        => 0,
        'IPC::Open3'        => 0,
        'IPC::Cmd'          => 0,
        'P4'                => 0,
        'Symbol'            => 0,
    },
    add_to_cleanup      => [ 'P4-Server-*' ],
);

$builder->create_build_script();
