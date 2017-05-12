use Test::More tests => 6;
use Number::Phone::Normalize;

my %par = ( 'CountryCode'=>'49', 'AreaCode'=>'99', 'VanityOK'=>1 );

is(phone_intl('+49 99-VANITY', 	%par),	'+49 99 VANITY');
is(phone_intl('099 VANITY', 	%par),	'+49 99 VANITY');
is(phone_intl('VANITY',		%par),	'+49 99 VANITY');

is(phone_local('+49 99-VANITY', %par),	'VANITY');
is(phone_local('099 VANITY', 	%par),	'VANITY');
is(phone_local('VANITY',	%par),	'VANITY');
