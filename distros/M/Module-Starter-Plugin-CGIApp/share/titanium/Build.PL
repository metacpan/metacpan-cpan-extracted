use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name           => '<tmpl_var distro>',
    module_name         => '<tmpl_var main_module>',
    dist_abstract       => 'Abstract goes here.',
    dist_author         => '<tmpl_var author> <<tmpl_var email>>',
    license             => '<tmpl_var license>',
    dist_version_from   => '<tmpl_var main_pm_file>',
    share_dir           => 'share',
    build_requires => {
        'Test::More'                    => 0,
        'Test::WWW::Mechanize::CGIApp'  => 0,
    },
    requires => {
        'perl'                          => 5.006,
        'Titanium'                      => 0,
        'HTML::Template'                => 0,
    },
    add_to_cleanup      => [ '<tmpl_var distro>-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
);

$builder->create_build_script();

