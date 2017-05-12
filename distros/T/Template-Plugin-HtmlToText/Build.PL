use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Plugin::HtmlToText',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Template/Plugin/HtmlToText.pm',
    create_makefile_pl  => 'traditional',
    build_requires => {
    	'Test::More' => 0,
        'Template'   => 0,
        'HTML::TreeBuilder' => 0,
        'HTML::FormatText'  => 0,
    },
);
$builder->create_build_script();

1;