use Test::More tests => 6;
use Number::Phone::Normalize;

is(phone_intl('+49 89-32168', 'CountryCode'=>49), 	'+49 89 32168');
is(phone_intl('+49 89-32168', 'CountryCode'=>44),	'+49 89 32168');

is(phone_intl('089 32168', 'CountryCode'=>49), 	'+49 89 32168');
is(phone_intl('089 32168', 'CountryCode'=>44),	'+44 89 32168');

is(phone_intl('32168', 'CountryCode'=>49, 'AreaCode'=> 89), '+49 89 32168');
is(phone_intl('32168', 'CountryCode'=>49, 'AreaCode'=> 99), '+49 99 32168');
