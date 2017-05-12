use Module::Build;
my $build = Module::Build->new
(
 module_name => 'Parse::Range',
 license  => 'bsd',
 create_makefile_pl => 'passthrough',
 requires => {
                  'List::MoreUtils'          => '0.22',
				  'Test::More'				 => '0.92',
},
);
$build->create_build_script;