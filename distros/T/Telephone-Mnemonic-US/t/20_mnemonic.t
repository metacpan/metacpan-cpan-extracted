
use Test::More  'no_plan';
use Telephone::Mnemonic::US qw/ to_words /;
use List::MoreUtils qw/ any /;

can_ok 'Telephone::Mnemonic::US', qw/ to_num to_words /;
can_ok 'Telephone::Mnemonic::US', qw/ printthem printvalids /;

#say Dumper to_words('2628');
#ok  any {$_ eq 'boat'} to_words('2628');

#is to_words('835-5837-4966'),'tellverizon';
