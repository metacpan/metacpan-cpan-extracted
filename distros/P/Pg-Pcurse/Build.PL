use Module::Build;
my $b= Module::Build->new(
        module_name        => 'Pg::Pcurse',
        dist_version_from  => 'lib/Pg/Pcurse.pm',
        dist_author        => 'Ioannis Tambouras<ioannis@cpan.org>',
        requires           => {  
#			   'perl'                => '5.008',
			   'Log::Log4perl'       => '1.06',
			   'DBIx::Abstract'      => '1.006',
			   'Carp::Assert'        => '0.18',
			   'Curses'              => '1.23',
			   'Curses::Widgets'     => '1.997',
			   'Getopt::Long'        => '2.35',
			   'File::Slurp'         => '9999.12',
			   'User::pwent'         => '1.00',
			   #'FindBin'            => '1.47',
},
recomends => {
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
              'Expect'              => '1.21',
}
;
        #script_files       =>  [ 'script/pcurse' ],
        #license            => 'gpl',
        #create_readme     => 1,
);

$b->create_build_script;

