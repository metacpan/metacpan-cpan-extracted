use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Net::DAAP::Server',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
        'Class::Accessor'   => 0,
        'File::Find::Rule'  => 0,
        'MP3::Info'         => 0,
        'Net::DMAP::Server' => 0,
        'Perl6::Slurp'      => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Net::DAAP::Client' => 0.41,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
