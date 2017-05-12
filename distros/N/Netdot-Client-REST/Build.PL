use Module::Build;
my $build = Module::Build->new
    (
     module_name        => 'Netdot::Client::REST',
     license            => 'perl',
     create_makefile_pl => 'traditional',
     requires           => {
         'perl'         => '5.8.0',
	 'LWP'          => 0,
	 'XML::Simple'  => 0,
	 'Data::Dumper' => 0,
     },
     );
$build->create_build_script;
