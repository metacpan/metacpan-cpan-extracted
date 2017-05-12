use 5.010000;
#use ExtUtils::MakeMaker;
use inc::Module::Install;

name           'Telephone-Mnemonic-US'          ;
license        'perl'                           ;
all_from       'lib/Telephone/Mnemonic/US.pm'   ;
install_script 'script/tel2num.pl'              ;
install_script 'script/tel2mnemonic.pl'         ;
no_index       'directory'   => 'examples'      ;
#author         'Ioannis Tambouras <ioannis@cpan.org>';

requires #'Log::Log4perl'       => '1.06',
	     #'Data::Dumper'        => '2.131',
#	     'Carp::Assert'        => '0.20',
	     'Getopt::Compact'     => '0.04',
	     'Moose'               => '2.0007',
	     'List::MoreUtils'     => '0.32',
         'namespace::autoclean'=> '0.12',
	     'List::Util'          => '1.23',
	     'Tie::DictFile'       => '0.03',
	     #'Math:::Combinatorics'         => '0',
;
test_requires 'Test::Pod::Coverage' => '1.08',
              'Test::Pod'           => '1.45',
              'Test::Pod::Coverage' => '1.08',
              'Test::HasVersion'    => '0.012',
              'Test::CPAN::Meta'    => '0.18',
              'Test::Exception'     => '0.31',
              'Test::Dependencies'  => '0.12',
              'Test::MinimumVersion'=> '0.101080',
              'Test::Strict'        => '0.14', 
              'Test::Spelling'      => '0.15',
              'Expect'              => '1.21',
;
auto_install;
WriteAll;
 grep { -f $_} qw{ /usr/dict/words /usr/share/dict/words } or
warn "WARNING: Could not find your dict/words file in the standard places. Until you get it, you can ony map mneumerics to numbers.\n";
