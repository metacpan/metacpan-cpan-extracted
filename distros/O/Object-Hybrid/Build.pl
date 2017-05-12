use Module::Build;
my $build = Module::Build->new(
	module_name => 'Object::Hybrid',
	dist_version => '0.07',
	license  => 'perl',
	requires => {
		'perl'           => '5.006',
		#'Class::Tag'     => 0, # now included, so it is not a prerequisite build
		#'Some::Module'  => '1.23',
		#'Other::Module' => '>= 1.2, != 1.5, < 2.0',
	},
	#create_makefile_pl => 'traditional', # already have one created with h2xs and patched to ignore Build.pl (see Module::Build docs)
	
);
$build->create_build_script;

