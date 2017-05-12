use Test::More  'no_plan';
use List::MoreUtils  qw/ any none/;
use Telephone::Mnemonic::US qw/ to_num to_words /;


is to_num('amaritrade'), '(262) 748 7233', 'map from mnemonic word';


exit;
ok any {$_ eq 'boat'}  to_words('2628') ;
ok any {$_ eq 'coat'}  to_words('2628') ;
ok none {$_ eq 'fail'}  to_words('2628') ;

ok ! to_words('22222222263-748-7233',1), 'with timeout';


SKIP: {
	my $dev_testing = (getlogin eq 'ioannis') && 0 ;
	skip 'dev testing' unless $dev_testing ;
	is to_words('263-748-7233'),'ameritrade', 'dev testing';
}
