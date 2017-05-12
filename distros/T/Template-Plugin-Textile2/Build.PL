use strict;
use Module::Build;

my %arguments = (
    #create_makefile_pl => 'passthrough',
    create_makefile_pl  => 'traditional',
    license            => 'perl',
    module_name        => 'Template::Plugin::Textile2',
    requires           => {
        'Template'          => 2.15,
        'Text::Textile'     => 2.03,
    },
    build_requires      => {
#        'Test::Exception'   => 0
    },
);

my $build = Module::Build->new(%arguments);
$build->create_build_script();
