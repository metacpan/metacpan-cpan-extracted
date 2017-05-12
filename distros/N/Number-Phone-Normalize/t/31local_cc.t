use Test::More tests => 9;
use Number::Phone::Normalize;

is(phone_local('32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AlwaysLD'=>1,                     ), '089 32168');
is(phone_local('32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AlwaysLD'=>1, 'CountryCodeOut'=>49), '089 32168');
is(phone_local('32168', 'CountryCode'=>44, 'AreaCode'=>89, 'AlwaysLD'=>1, 'CountryCodeOut'=>49), '0044 89 32168');

is(phone_local('089 32168', 'CountryCode'=>49,                     ),	'089 32168');
is(phone_local('089 32168', 'CountryCode'=>49, 'CountryCodeOut'=>49),	'089 32168');
is(phone_local('089 32168', 'CountryCode'=>44, 'CountryCodeOut'=>49),	'0044 89 32168');

is(phone_local('+49 89 32168', 'CountryCode'=>49, 'CountryCodeOut'=>49),	'089 32168');
is(phone_local('+49 89 32168', 'CountryCode'=>44, 'CountryCodeOut'=>49),	'089 32168');
is(phone_local('+44 89 32168', 'CountryCode'=>44, 'CountryCodeOut'=>49),	'0044 89 32168');
