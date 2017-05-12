use Module::Build;
my $class = eval { require Mite::ModuleBuild } || 'Module::Build';

my $build = $class->new(
    module_name         => 'Some::Project',
    license             => 'perl',
);
$build->create_build_script;
