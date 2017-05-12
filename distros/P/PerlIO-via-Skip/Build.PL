use Module::Build;
my $b= Module::Build->new(
	module_name        => 'PerlIO::via::Skip',
	dist_author        => 'Ioannis Tambouras <ioannis@cpan.org>',
	requires           => { perl => '5.006'},
	recommends         => { 
							'Test::Distribution'  => '1.22',
							'Test::Exception'     => 0,
							'Test::Pod::Coverage' => '1.08',
							'Test::Pod'           => '1.45',
							'Test::Pod::Coverage' => '1.08',
							'Test::HasVersion'    => '0.012',
							'Test::CPAN::Meta'    => '0.18',
							'Test::Exception'     => '0.31',
							'Test::Distribution'  => '2.00',
							'Test::Dependencies'  => '0.12',
							'Test::MinimumVersion'=> '0.101080',
							'Test::Strict'        => '0.14',
							'Test::Spelling'      => '0.15',
	                      },
	license            => 'perl',
	create_makefile_pl=> 'traditional',
	#create_readme     => 1,
);


$b->create_build_script;
#$b->manifest;
