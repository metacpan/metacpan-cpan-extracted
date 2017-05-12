use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Orze',
    all_from            => 'Orze',
    license             => 'perl',
    dist_author         => 'Olivier Schwander <iderrick@cpan.org>',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'DateTime'              => 0,
        'File::Copy::Recursive' => 0,
        'HTML::Entities'        => 0,
        'Image::Thumbnail'      => 0,
        'Pod::Simple::XHTML'    => 0,
        'String::Escape'        => 0,
        'Template'              => 0,
        'Text::Markdown'        => 0,
        'XML::RSS'              => 0,
        'XML::Twig'             => 0,
        'YAML'                  => 0,
		  'Data::Dump'            => 0,
    },
    script_files => ['script/orze'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

