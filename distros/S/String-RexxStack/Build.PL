use Module::Build;
my $b= Module::Build->new(
	module_name        => 'String::RexxStack',
	dist_version_from  => 'lib/String/RexxStack/Named.pm',
	dist_author        => 'Ioannis Tambouras <ioannis@yahoo.com>',
	requires           => {  perl               => '5.6',
                                'Class::MethodMaker'=> 0,
                                'Filter::Simple'    => 0,
                                'Want'              => 0,
                                'Data::Dumper'      => 0,
                              },
	recommends         => { 'Test::More'         => 0,
                                'Pod::Checker'       => 0,
	                        'Test::Pod::Coverage'=> '1.06',
				'Test::Pod'          => '1.20',
                                'Test::Distribution' => '1.22',
			      },
	license            => 'gpl',
	#create_makefile_pl=> 'traditional',
	#create_readme     => 1,
);

$b->create_build_script;
#$b->dispatch( 'manifest' );
