use v5.10;
use inc::Module::Install;

name           'Pg-Loader'                ;
license        'perl'                     ;
all_from       'lib/Pg/Loader.pm'         ;
install_script 'script/pgloader.pl'       ;
no_index       'directory'   => 'examples';

requires        'Log::Log4perl'        =>  '1.16',
               	'Text::Table'          =>  '1.107',
               	'Storable'             =>  '2.18',
	       	    'DBD::Pg'              =>  '2.10.7',
               	'Time::HiRes'          =>  '1.9711',
	       	    'List::MoreUtils'      =>  '0.22',
		        'Config::Format::Ini'  =>  '0.05',
	            'Text::CSV'            =>  '1.06',
                'Quantum::Superpositions' => '2.02',
	            'Getopt::Compact'      =>  '0.04'  ,
;
		#'FindBin'             =>  '1.47',
		#'Carp::Assert'        =>  '0.18',
		#'File::Slurp'         =>  '9999.12',
		#'SQL::Abstract'       =>  '1.24',
    
test_requires   'Test::Pod::Coverage'  =>  '1.0',
                'Test::Pod'            =>  '1.0',
                'Test::MockDBI'        =>  '0.61',
                'Test::Exception'      =>  '0.27',
                'Test::HasVersion'     =>  '0.012',
                'Test::Dependencies'   =>  '0.11',
                'Test::CPAN::Meta'     =>  '0.12',
                'Expect'               =>  '1.21',
                'Test::MinimumVersion' =>  '0.101080',
                'Test::Spelling'       =>  '0.15',
                'Test::Legal'          =>  '0.10',
;

auto_install;
WriteAll;


#print  "\nIt takes 2 seconds. This time read the README file!\n\n";
