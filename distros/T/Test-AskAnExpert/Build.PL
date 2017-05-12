use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::AskAnExpert',
    license     => 'open_source',
    requires    => {
	perl => '5.6.2'
    },
    create_makefile_pl => 'traditional',
    sign	=> 1
);
$build->create_build_script;
