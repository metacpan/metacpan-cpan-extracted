use Test::More tests => 12;
use Number::Phone::Normalize;

is(phone_local('32168', 'AreaCode'=>89,                   ), '32168');
is(phone_local('32168', 'AreaCode'=>89, 'AreaCodeOut'=> 89), '32168');
is(phone_local('32168', 'AreaCode'=>89, 'AreaCodeOut'=>999), '089 32168');

is(phone_local('089 32168', 'AreaCode'=>89,                   ), '32168');
is(phone_local('089 32168', 'AreaCode'=>89, 'AreaCodeOut'=> 89), '32168');
is(phone_local('089 32168', 'AreaCode'=>89, 'AreaCodeOut'=>999), '089 32168');

is(phone_local('+49 89 32168', 'AreaCode'=>89,                   ), '0049 89 32168');
is(phone_local('+49 89 32168', 'AreaCode'=>89, 'AreaCodeOut'=> 89), '0049 89 32168');
is(phone_local('+49 89 32168', 'AreaCode'=>89, 'AreaCodeOut'=>999), '0049 89 32168');

is(phone_local('32168'), '32168');
is(phone_local('089 32168'), '089 32168');
is(phone_local('+49 89 32168'), '0049 89 32168');
