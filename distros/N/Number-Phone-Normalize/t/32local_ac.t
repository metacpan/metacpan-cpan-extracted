use Test::More tests => 9;
use Number::Phone::Normalize;

is(phone_local('32168', 'CountryCode'=>49, 'AreaCode'=>89,                   ), '32168');
is(phone_local('32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AreaCodeOut'=> 89), '32168');
is(phone_local('32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AreaCodeOut'=>999), '089 32168');

is(phone_local('089 32168', 'CountryCode'=>49, 'AreaCode'=>89,                   ), '32168');
is(phone_local('089 32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AreaCodeOut'=> 89), '32168');
is(phone_local('089 32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AreaCodeOut'=>999), '089 32168');

is(phone_local('+49 89 32168', 'CountryCode'=>49, 'AreaCode'=>89,                   ), '32168');
is(phone_local('+49 89 32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AreaCodeOut'=> 89), '32168');
is(phone_local('+49 89 32168', 'CountryCode'=>49, 'AreaCode'=>89, 'AreaCodeOut'=>999), '089 32168');
