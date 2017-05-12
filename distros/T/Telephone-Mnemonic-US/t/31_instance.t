
use Test::More  'no_plan';
use Telephone::Mnemonic::Phone;
use Telephone::Mnemonic::US::Phone;
use Data::Dumper;
use Test::Exception;


my $num= '123-111-222';

note 'US::Phone instance';
my $u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ num=>'123-111-3333'] ;
is $u1->area_code, 123;
is $u1->station_code, 111;
is $u1->house_code, 3333;
is $u1->without_area_code, '1113333';
is $u1->beautify, '(123) 111 3333';

note 'US::Phone to_num';
$u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ num=>'ameritrade'] ;
is $u1->beautify, '(263) 748 7233';

$u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ num=>'(263) 748 7233'] ;
#say Dumper $u1->to_word;
#is $u1->to_word, 'ameritrade';

__END__
