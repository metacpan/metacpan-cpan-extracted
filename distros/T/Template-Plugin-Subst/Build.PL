use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::Subst',
    license             => 'bsd',
    dist_author         => 'Nik Clayton <nik@FreeBSD.org>',
    dist_version_from   => 'lib/Template/Plugin/Subst.pm',
    requires => {
        'Test::More' => 0,
	'Template'   => 0,
    },
    add_to_cleanup      => [ 'Template-Plugin-Subst-*' ],
    create_readme	=> 1,
    sign		=> 1,
    create_makefile_pl	=> 'passthrough',
);

$builder->create_build_script();
