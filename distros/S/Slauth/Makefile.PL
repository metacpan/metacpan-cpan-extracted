#!perl
use ExtUtils::MakeMaker;

use lib qw(../blib/lib lib );
  
use Apache::TestMM qw(test clean); #enable 'make test'

# prerequisites
my %require =
(
	"Apache::Test" => "", # any version will do
	"Digest::MD5" => 0,
	"CGI" => 3.00,
	"CGI::Carp" => 1.28,
	"CGI::Cookie" => 1.24,
);

# cleanup list
my @clean_scripts = qw( t/TEST t/slauth.conf );
my @clean_data = qw( t/conf/user-localhost.db );

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
	'NAME'          => 'Slauth',
	'VERSION_FROM'  => 'lib/Slauth.pm',
	'ABSTRACT_FROM' => 'lib/Slauth.pm',
	'AUTHOR'	=> 'ikluft@thunder.sbay.org (Ian Kluft)',
	'PREREQ_PM'	=> \%require,
	'EXE_FILES'	=> [ 'script/slauth-adduser' ],
	'clean'		=> { 'FILES' => join( " ",
				@clean_scripts, @clean_data )},
);
