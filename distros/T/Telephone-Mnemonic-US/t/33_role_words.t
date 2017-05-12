
use Test::More  'no_plan';
use Telephone::Mnemonic::US::Phone;
use Data::Dumper;
use Test::Exception;


my $num= '123-111-222';

note 'US::Phone construction';
my $u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ num=>'123-111-3333'] ;
$u1 = new_ok 'Telephone::Mnemonic::US::Phone', [ '723-233-4332'] ;
can_ok $u1, qw/ result dict timeout/;
ok ! $u1->can( $_)    for qw/ to_digits str_pairs dict_path find_valids /;

no strict 'refs';
ok defined $u1->$_ , qq($_... defined)  for qw/ dict timeout /


#say $u1->to_words();
#is $u1->what('apple'), 'apple' ;

