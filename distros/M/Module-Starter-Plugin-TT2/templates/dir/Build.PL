
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => '[%main_module%]',
    license             => '[%self.license%]',
    dist_author         => '[%self.author%] <[%self.email%]>',
    dist_version_from   => '[%main_pm_file%]',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ '[%self.distro%]-*' ],
);

$builder->create_build_script();
