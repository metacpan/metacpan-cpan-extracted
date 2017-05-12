use Test::More 'no_plan';
use List::MoreUtils  qw/ any none/;
use Telephone::Mnemonic::US::Math qw/  seg_words dict_path/;
use Tie::DictFile;

my %dict;
tie %dict, 'Tie::DictFile', dict_path ;
 

sub contains {
	my ($value, @list) = @_;
	$value || @list || return;
	any { $_ eq $value } @list;
}

(contains  $_,  seg_words('2628',\%dict)  )
	? ok( 1) 
	: note qq/warning: "$_" not in dict/  for (qw/coat boat coat anat/);

ok!  contains  'fafafafa',  seg_words('coat',\%dict) ;
ok ! contains  'fail',  seg_words('2628',\%dict) ;

ok ! seg_words('22222222263-748-7233',\%dict,1), 'with timeout';

SKIP: {
	my $dev_testing = (getlogin eq 'ioannis') && 0 ;
	skip 'dev testing' unless $dev_testing ;
	ok any {$_ eq 'boat'}  seg_words('263-748-7233',\%dict),'ameritrade', 'dev testing';

}
