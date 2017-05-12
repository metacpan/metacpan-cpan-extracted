use Module::Build;
# See perldoc Module::Build for details of how this works

my $build = Module::Build->new
(
    module_name     => 'Template::Plugin::HashMerge',
    dist_author     => 'Jens Rehsack <rehsack@cpan.org>',
    license         => 'perl',
    requires        => {
        'Hash::Merge'     => '0.09',
        'Template'        => '2.20',
        'Template::Plugin::VMethods' => '0.02',
    },
    recommends      => {
    },
    create_makefile_pl => 'traditional',
);
$build->create_build_script;
