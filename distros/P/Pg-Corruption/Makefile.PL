use 5.012000;
use inc::Module::Install;

name           'Pg-Corruption'              ;
license        'perl'                       ;
all_from       'lib/Pg/Corruption.pm'       ;
install_script 'script/pk_corrupt.pl'       ;
install_script 'script/fk_corrupt.pl'       ;
no_index       'directory'   => 'examples'  ;

requires        #'Log::Log4perl'        =>  '1.16',
             #  	'Text::Table'          =>  '1.107',
	       	    'DBD::Pg'              =>  '2.10.7',
             #  	'Time::HiRes'          =>  '1.9711',
	       	 #   'List::MoreUtils'      =>  '0.22',
	            'Getopt::Compact'      =>  '0.04'  ,
;
    
test_requires   'Test::Pod::Coverage'  =>  '1.0',
                'Test::Pod'            =>  '1.0',
                #'Test::MockDBI'        =>  '0.61',
                #'Test::Exception'      =>  '0.27',
                'Test::HasVersion'     =>  '0.012',
                'Test::Dependencies'   =>  '0.11',
                'Test::CPAN::Meta'     =>  '0.12',
   #             'Expect'               =>  '1.21',
                'Test::MinimumVersion' =>  '0.101080',
                'Test::Spelling'       =>  '0.15',
;

auto_install;
WriteAll;


