use Module::Build;
my $build = Module::Build->new(
	(sign => 1),
	module_name => 'Pod::Coverage::MethodSignatures',
	license  => 'perl',

	configure_requires => {
		'Module::Build' => '0.360300',
	},

	build_requires => {
		'Method::Signatures' => '20100730',
		'Test::More'          => '0.92',
		'Test::Output'        => '0.16',
	},

	requires => {
		'perl'          => '5.8.1',
		'Pod::Coverage' => '0.20',
	},

	dist_author => 'Darian Anthony Patrick <dap@darianpatrick.com>',
	meta_merge => {
		resources => {
			license    => 'http://dev.perl.org/licenses/',
			bugtracker =>
				'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod::Coverage::MethodSignatures',
			repository => 'https://github.com/dap/Pod-Coverage-MethodSignatures/tree',

		},
	},
	create_readme => 1,
	create_license => 1,
);
$build->create_build_script;
