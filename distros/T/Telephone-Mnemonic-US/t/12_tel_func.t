
use Test::More  'no_plan';
use Telephone::Mnemonic::US::Number qw/ 
				well_formed_p area_code without_area_code 
				to_tel_digits beautify
/;
*_filter_numbers = *Telephone::Mnemonic::US::Number::_filter_numbers ;



is  beautify('7031112244'), '(703) 111 2244';

ok well_formed_p( '(734) 555 1212');
ok ! well_formed_p( '4-555 1212');

is _filter_numbers(' (734) 555 1212'), '7345551212';
is area_code( '(734) 555 1212'), 734 ;
is area_code( '555 1212'), undef ;
is without_area_code( '(734) 555 1212'), '5551212';
is without_area_code( '555 1212'), '5551212';
is to_tel_digits( 'boa t212'), '2628212';
