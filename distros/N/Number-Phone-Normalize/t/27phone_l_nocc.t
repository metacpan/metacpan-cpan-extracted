use Test::More tests => 6;
use Number::Phone::Normalize;

my %par = (AreaCode=>'89');

is(phone_local('0999 12345678', %par), '0999 12345678');
is(phone_local('089 32168', %par), '32168');
is(phone_local('32168', %par), '32168');

%par = (AreaCode=>'89', 'AlwaysLD' => 1);

is(phone_local('0999 12345678', %par), '0999 12345678');
is(phone_local('089 32168', %par), '089 32168');
is(phone_local('32168', %par), '089 32168');
