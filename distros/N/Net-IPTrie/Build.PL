use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'Net::IPTrie',
     license     => 'perl',
     requires    => {
	 'perl'          => '5.8.0',
	 'Class::Struct' => '0.63',
	 'Scalar::Util'  => '1.21',
	 'Test::More'    => '0',
	 'NetAddr::IP'   => '4.007',
     },
     create_makefile_pl => 'traditional',
     );
$build->create_build_script;
