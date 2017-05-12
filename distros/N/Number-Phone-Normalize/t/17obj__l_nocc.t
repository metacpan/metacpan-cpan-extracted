use Test::More tests => 6;
use Number::Phone::Normalize;

my $obj = Number::Phone::Normalize->new(
  AreaCode=>'89');

is($obj->local('0999 12345678'), '0999 12345678');
is($obj->local('089 32168'), '32168');
is($obj->local('32168'), '32168');

$obj = Number::Phone::Normalize->new(
  AreaCode=>'89',
  'AlwaysLD' => 1);

is($obj->local('0999 12345678'), '0999 12345678');
is($obj->local('089 32168'), '089 32168');
is($obj->local('32168'), '089 32168');
