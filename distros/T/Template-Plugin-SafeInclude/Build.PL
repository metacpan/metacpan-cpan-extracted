use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::SafeInclude',
    license             => 'perl',
    dist_author         => 'yuya matsumoto <my3594@gmail.com>',
    dist_version_from   => 'lib/Template/Plugin/SafeInclude.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Template-Plugin-SafeInclude-*' ],
);

$builder->create_build_script();
