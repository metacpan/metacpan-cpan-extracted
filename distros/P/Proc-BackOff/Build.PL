use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl  => 'traditional',
    license             => 'artistic',
    create_packlist     => 1,
    create_readme       => 1,
    module_name         => 'Proc::BackOff',
    requires            => {
        'Class::Accessor' => 0,
    },
    dist_author => 'Daniel Lo <daniel_lo@picturetrail.com>',
    dist_abstract => 'Random, Exponential, and Linear back off objects.',
);

$build->create_build_script;
