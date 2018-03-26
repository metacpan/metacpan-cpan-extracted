use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Table::Hack',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/Table/Hack.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        'cli::rows::util' => '0.31' , 
        'cli::rows::venn' => '0.001', 
        'cli::numbers::util' => '0.31' ,
        'cli::tsv::util' => '0.511', 
        'cli::tsv::keyvalue' => '0.31', 
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'Table-Hack-*' ],
);

$builder->create_build_script();
