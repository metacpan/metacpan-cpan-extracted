use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Package::Butcher',
    license            => 'perl',
    dist_author        => q{Curtis 'Ovid' Poe <ovid@cpan.org>},
    dist_version_from  => 'lib/Package/Butcher.pm',
    build_requires     => { 'Test::More' => 0, },
    add_to_cleanup     => ['Package-Butcher-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources => { repository => 'https://github.com/Ovid/Package-Butcher' }
    },
);

$builder->create_build_script();
