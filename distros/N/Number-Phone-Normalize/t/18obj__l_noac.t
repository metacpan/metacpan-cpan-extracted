use Test::More tests => 3;
use Number::Phone::Normalize;

my $obj = Number::Phone::Normalize->new();

is($obj->local('0999-12345678'), '0999 12345678');
is($obj->local('089-32168'), '089 32168');
is($obj->local('32168'), '32168');
