use Module::Build;
use 5.006000;

my $build = Module::Build->new(
        license            => 'perl',
        dist_author        => 'Dave Cross <dave@mag-sol.com>',
        module_name        => 'Parse::RPM::Spec',
        requires           => {
                perl       => '5.6.0',
		Moose      => 0,
        },
        build_requires     => {
                'Test::More'          => 0,
        },
        build_recommends   => {
                'Test::Pod'           => 0,
                'Test::Pod::Coverage' => 0,
        },
        create_makefile_pl => 'traditional',
);

$build->create_build_script;
