use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Squid::Purge',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@socklabs.com>',
    dist_version_from   => 'lib/Net/Squid/Purge.pm',
    requires => {
        'Net::HTTP' => 0,
        'HTTP::Status' => 0,
        'Class::Accessor' => 0,
        'Socket' => 0,
        'IO::Socket::Multicast' => 0,
        'IO::Socket::INET' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Group' => 0,
        'Test::Exception' => 0,
    },
    add_to_cleanup      => [ 'Net-Squid-Purge-*' ],
);

$builder->create_build_script();
