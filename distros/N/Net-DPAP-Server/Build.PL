use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Net::DPAP::Server',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
        'Class::Accessor'   => 0,
        'File::Find::Rule'  => 0,
        'Image::Imlib2'     => 0,
        'Image::Info'       => 0,
        'Net::DMAP::Server' => 0,
        'Perl6::Slurp'      => 0,
    },
    build_requires => {
        'Net::DPAP::Client' => 0,
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
