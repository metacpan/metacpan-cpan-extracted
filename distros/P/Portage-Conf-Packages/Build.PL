use Module::Build;
my $build = Module::Build->new
(
	module_name => 'Portage::Conf::Packages',
    license  => 'perl',
    requires => {
                 'perl'          => '5.6.1',
                 'Tie::File'  => '0',
		    },
	create_makefile_pl => 'passthrough',
);
$build->create_build_script;
