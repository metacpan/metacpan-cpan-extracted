use strict;
use warnings;
use Test::More;

eval "require 5.006_001";
plan skip_all => "perl 5.6.1 required for testing exists(&func)" if $@;

plan tests => 3;
use_ok('Temperature::Windchill');
ok(exists &Temperature::Windchill::windchill_us);
ok(exists &Temperature::Windchill::windchill_si);

