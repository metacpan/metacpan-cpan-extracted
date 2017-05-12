use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::XMPP3',
    license             => 'lgpl',
    dist_author         => 'guruperl',
    dist_abstract		=> 'XMPP3 Support Library',
    dist_version_from   => 'lib/Net/XMPP3.pm',
    requires => {
        'XML::Stream' => 1.22,
        'Digest::SHA1' => 1.02,
    	},
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();


