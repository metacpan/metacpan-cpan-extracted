use v5.10;
use inc::Module::Install;

name           'Pg-Pcurse'                ;
license        'GPL_3'                    ;
all_from       'lib/Pg/Pcurse.pm'         ;
install_script 'script/pcurse'            ;
no_index       'directory'   => 'examples';

requires        
				'Log::Log4perl'       => '1.16',
				'DBIx::Abstract'      => '1.006',
				'Carp::Assert'        => '0.18',
				'Curses'              => '1.23',
				'Curses::Widgets'     => '1.997',
				'Getopt::Long'        => '2.35',
				'File::Slurp'         => '9999.12',
				'User::pwent'         => '1.00',
	       	    'DBD::Pg'             => '2.10.7',
;
    
test_requires   'Test::Pod::Coverage'  => '1.0' ,
				'Test::Exception'      => '0.31',
				'Test::Pod::Coverage'  => '1.0' ,
				'Test::Pod'            => '1.45',
				'Test::HasVersion'     => '0.012',
				'Test::CPAN::Meta'     => '0.18',
				'Test::Exception'      => '0.31',
				'Test::Distribution'   => '2.00',
				'Test::Dependencies'   => '0.12',
				'Test::MinimumVersion' => '0.101080',
				'Test::Strict'         => '0.14',
				'Test::Spelling'       => '0.15',
				'Expect'               => '1.21',
                'Test::MinimumVersion' =>  '0.101080',
                'Test::Spelling'       =>  '0.15',
                'Test::Legal'          =>  '0.10',
;

auto_install;
WriteAll;
