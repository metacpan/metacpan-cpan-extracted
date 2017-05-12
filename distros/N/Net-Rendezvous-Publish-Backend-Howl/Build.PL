use strict;
use Module::Build;

Module::Build->new(
    module_name => "Net::Rendezvous::Publish::Backend::Howl",
    license     => 'perl',
    requires    => {
        'perl'          => '5.006',
        'Net::Rendezvous::Publish' => 0,
        'Class::Accessor::Lvalue' => 0,
        'Test::More'    => 0,
    },
    extra_compiler_flags => `pkg-config howl --cflags` || '-I/usr/include/howl',
    extra_linker_flags   => `pkg-config howl --libs` || '-lhowl',
    create_makefile_pl   => 'passthrough',
   )
  ->create_build_script;
