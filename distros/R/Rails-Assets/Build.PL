use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Rails::Assets',
    license             => 'artistic_2',
    dist_author         => q{Mauro Berlanda <kupta@cpan.org>},
    dist_version_from   => 'lib/Rails/Assets.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
        'Test::Output' => '0',
        'Test::Deep' => '0',
        'File::Basename' => '0',
        'File::Spec' => '0',
        'File::Spec::Functions' => '0',
        'File::Find' => '0',
        'Devel::Cover' => '0',
    },
    requires => {
        'Clone' => '0',
        'YAML' => '0',
        'YAML::Dumper' => '0',
    },
    add_to_cleanup     => [ 'Rails-Assets-*' ],
);

$builder->create_build_script();
