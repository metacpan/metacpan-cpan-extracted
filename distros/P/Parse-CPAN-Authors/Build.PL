use Module::Build;
use strict;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Parse::CPAN::Authors',
    requires           => {
        'IO::Zlib'              => 0,
        'Test::Exception'       => 0,
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
    },
);
$build->create_build_script;
