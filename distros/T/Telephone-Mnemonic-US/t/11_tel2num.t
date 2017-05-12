use Test::More  'no_plan';
use Telephone::Mnemonic::US qw/ to_num /;

is to_num('ameritrade'), '(263) 748 7233';
is to_num('ameritra33'), '(263) 748 7233';
is to_num('26e.ritra33'), '(263) 748 7233';
is to_num('(26e) rit ra33'), '(263) 748 7233';
is to_num('123a334'), '123 2334';
ok ! to_num('a33');


#is to_num('boat'), '2628';
#is to_num('tellverizon'), '835-5837 4966';
