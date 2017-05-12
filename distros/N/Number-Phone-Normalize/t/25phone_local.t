use Test::More tests => 7;
use Number::Phone::Normalize;

%par = ( CountryCode=>'49', AreaCode=>'89');

is(phone_local('+1 555 123 4567', %par), '001 555 123 4567');
is(phone_local('001 555 123 4567', %par), '001 555 123 4567');

is(phone_local('+49 999 12345678', %par), '0999 12345678');
is(phone_local('0999 12345678', %par), '0999 12345678');

is(phone_local('+49 89 32168', %par), '32168');
is(phone_local('089 32168', %par), '32168');
is(phone_local('32168', %par), '32168');
