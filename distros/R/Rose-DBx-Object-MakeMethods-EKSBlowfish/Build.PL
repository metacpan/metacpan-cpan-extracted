use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Rose::DBx::Object::MakeMethods::EKSBlowfish',
    license             => 'Artistic_2_0',
    dist_author         => q{Holger Rupprecht <holger.rupprecht@gmx.de>},
    dist_version_from   => 'lib/Rose/DBx/Object/MakeMethods/EKSBlowfish.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
		  'Rose::DBx::TestDB' => '0.05',
    },
    requires => {
        'Rose::DB'                     => 0.770,
        'Rose::DB::Object'             => 0.804,
        'Crypt::Eksblowfish::Bcrypt'   => 0.009,
    },
    add_to_cleanup     => [ 'Rose-DBx-Object-MakeMethods-EKSBlowfish-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
