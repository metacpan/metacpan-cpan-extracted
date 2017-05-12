use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'PerlIO::via::CBC',
    requires           => { 'Crypt::CBC' => '2.12', 'Crypt::DES' => '2.03' },
    reccomends         => {},
    create_readme      => 1,
    sign               => 0,
);
$build->create_build_script;
