use strict;
use Module::Build;

Module::Build->new(
    module_name => "Net::Rendezvous::Publish::Backend::Apple",
    license     => 'perl',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        "Net::Rendezvous::Publish" => 0,
        'Class::Accessor::Lvalue'  => 0,
    },
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;
