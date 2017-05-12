use Module::Build;

grep { -e "$_/flex" }  split /:/, $ENV{PATH}
    or print q(You need flex(1) in your $PATH.)  and exit;


my $b= Module::Build->new(
	module_name        => 'Parse::Flex',
	dist_author        => 'Ioannis Tambouras <ioannis@yahoo.com>',
	requires           => { perl           => '5.006',
				'Scalar::Util' =>    0 ,
				XSLoader       =>    0 ,
			      },
	recommends         => { 'Test::Pod'           => '1.20',
                                'Test::Pod::Coverage' => '1.06',
                                'Test::Distribution'  => '1.22',
				'Pod::Checker'        =>  0 ,
				'Test::Exception'     =>  0 ,
	                      },
	license            => 'perl',
	script_files       => [ 'script/makelexer.pl' ],
	add_to_cleanup     => [ 't/Flex7.so', 't/Flex7.pm' ],

	#create_makefile_pl=> 'traditional',
	#create_readme     => 1,
);


$b->create_build_script;
#$b->manifest;
