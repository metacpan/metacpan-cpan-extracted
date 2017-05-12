
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name  => 'Net::Backpack',
    dist_version => '1.15',
    license      => 'perl',
    requires     => {
        'LWP::UserAgent' => 0,
        'HTTP::Request'  => 0,
        'XML::Simple'    => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
);

$build->create_build_script;
