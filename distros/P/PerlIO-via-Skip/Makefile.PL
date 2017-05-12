use 5.006;
#use ExtUtils::MakeMaker;
use inc::Module::Install;

name           'PerlIO-via-Skip'                ;
license        'perl'                           ;
all_from       'lib/PerlIO/via/Skip.pm'         ;
author         'Ioannis Tambouras <ioannis@cpan.org>';
abstract_from  'lib/PerlIO/via/Skip.pm'         ;
no_index       'directory'   => 'examples'      ;

requires #'Log::Log4perl'       => '1.06',
	     #'Data::Dumper'        => '2.131',
#	     'Carp::Assert'        => '0.20',
#     'Getopt::Compact'     => '0.04',
#	     'List::MoreUtils'     => '0.32',
#         'namespace::autoclean'=> '0.12',
#	     'List::Util'          => '1.23',
;
test_requires 'Test::Pod::Coverage' => '1.08',
              'Test::Pod'           => '1.45',
              'Test::Pod::Coverage' => '1.08',
              'Test::HasVersion'    => '0.012',
              'Test::CPAN::Meta'    => '0.18',
              'Test::Exception'     => '0.31',
              'Test::Distribution'  => '2.00';
              'Test::Dependencies'  => '0.12',
              'Test::MinimumVersion'=> '0.101080',
              'Test::Strict'        => '0.14', 
              'Test::Spelling'      => '0.15',
;
auto_install;
WriteAll;
