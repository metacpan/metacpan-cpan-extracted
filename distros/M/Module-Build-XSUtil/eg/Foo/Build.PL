use strict;
use warnings;
use Module::Build::XSUtil;

my $builder = Module::Build::XSUtil->new(
    name                 => 'Foo',
    module_name          => 'Foo',
    test_files           => 't/',
    license              => 'perl',
    dynamic_config       => 0,

    configure_requires  => { 'Module::Build::XSUtil' => 0, },
    generate_ppport_h   => 'lib/ppport.h',
    generate_xshelper_h => 'lib/xshelper.h',
);

$builder->create_build_script();
