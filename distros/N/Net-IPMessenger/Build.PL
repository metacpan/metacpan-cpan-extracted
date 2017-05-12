use strict;
use warnings;
use Module::Build;

require 5.008001;

my $builder = Module::Build->new(
    module_name         => 'Net::IPMessenger',
    license             => 'perl',
    dist_author         => 'Masanori Hara <massa.hara at gmail.com>',
    dist_version_from   => 'lib/Net/IPMessenger.pm',
    requires => {
        'Class::Accessor::Fast' => 0,
        'Encode'                => 0,
        'Test::More'            => 0,
    },
    add_to_cleanup      => [ 'Net-IPMessenger-*' ],
);

$builder->create_build_script();
