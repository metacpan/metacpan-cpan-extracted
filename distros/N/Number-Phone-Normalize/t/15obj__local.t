use Test::More tests => 7;
use Number::Phone::Normalize;

my $obj = Number::Phone::Normalize->new(
  CountryCode=>'49',
  AreaCode=>'89');

is($obj->local('+1 555 123 4567'), '001 555 123 4567');
is($obj->local('001 555 123 4567'), '001 555 123 4567');

is($obj->local('+49 999 12345678'), '0999 12345678');
is($obj->local('0999 12345678'), '0999 12345678');

is($obj->local('+49 89 32168'), '32168');
is($obj->local('089 32168'), '32168');
is($obj->local('32168'), '32168');
