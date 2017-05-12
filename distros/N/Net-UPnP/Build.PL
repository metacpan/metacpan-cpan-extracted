use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::UPnP',
    license             => 'bsd',
    dist_author         => 'Satoshi Konno <skonno@cybergarage.org>',
    dist_version_from   => 'lib/Net/UPnP.pm',
    abstract_from_from  => 'lib/Net/UPnP.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Net-UPnP-*' ],
);

$builder->create_build_script();
