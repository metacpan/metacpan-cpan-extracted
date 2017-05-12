use Test::More tests => 6;
use Number::Phone::Normalize;

my %par = ( 'CountryCode'=>'49', 'AreaCode'=>'99', 'VanityOK'=>1 );

is(phone_intl('+HZ ZZ-VANITY', 	%par),	'+HZ ZZ VANITY');
is(phone_intl('0-ZZ-VANITY', 	%par),	'+49 ZZ VANITY');
is(phone_intl('VANITY',		%par),	'+49 99 VANITY');

is(phone_local('+H-Z ZZ-VANITY', %par),	'VANITY');
is(phone_local('0-Z-Z VANITY', 	%par),	'VANITY');
is(phone_local('VANITY',	%par),	'VANITY');
