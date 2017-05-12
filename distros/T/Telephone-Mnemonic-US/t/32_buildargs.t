
use Test::More  'no_plan';
use Telephone::Mnemonic::US::Phone;
use Data::Dumper;
use Test::Exception;


my $num= '123-111-222';

note 'US::Phone construction';
my $u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ num=>'123-111-3333'] ;
$u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ '123-111-3333'] ;
no strict 'refs';
ok $u1->$_ , qq($_... defined)  for qw/ num area_code house_code station_code 
                                        without_area_code beautify/;

