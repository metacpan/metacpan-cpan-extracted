use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Net::DNS::Resolver::Programmable',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    requires        => {
        # Core requirements:
        perl            => 0,
        version         => 0,
        Net::DNS        => 0
    },
    recommends      => {
    },
    build_requires  => {
        # Build-only requirements:
        Module::Build   => '0.2805'
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();

# $Id: Build.PL 13 2007-05-30 22:12:35Z julian $
