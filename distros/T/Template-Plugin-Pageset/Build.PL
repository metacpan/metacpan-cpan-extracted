use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::Pageset',
    license             => 'perl',
    dist_author         => 'Chunzi <chunzi@chunzi.org>',
    dist_version_from   => 'lib/Template/Plugin/Pageset.pm',
    requires => { 'Test::More' => 0,
                  'Test::Exception' => 0,
                  'Data::Page::Pageset' => 1,
                  'Template' => 2,
                  Carp => 0,
                  },
    add_to_cleanup      => [ 'Template-Plugin-Pageset-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script;
