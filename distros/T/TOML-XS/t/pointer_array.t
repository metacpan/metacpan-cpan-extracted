#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use TOML::XS;

my $toml = <<END;
# This is a TOML document

"Löwe" = "Löwe"
boolean = false
integer = 123
double = 34.5
timestamp = 1979-05-27T07:32:00-08:00
somearray = []

[checkextra]
"Löwe" = "Löwe"
alltypes = [ { foo = "bar" }, [123], 05:12:23, 2026-01-01 ]
boolean = false
integer = 123
double = 34.5
timestamp = 1979-05-27T07:32:00-08:00
END

my $docobj = TOML::XS::from_toml($toml);

cmp_deeply(
    $docobj->get('checkextra', 'alltypes', 0),
    { foo => 'bar' },
    'get 0',
);

cmp_deeply(
    $docobj->get('checkextra', 'alltypes', 0, 'foo'),
    'bar',
    'get 0.foo',
);

cmp_deeply(
    $docobj->get('checkextra', 'alltypes', 1),
    [123],
    'get 1',
);

cmp_deeply(
    $docobj->get('checkextra', 'alltypes', 1, 0),
    123,
    'get 1.0',
);

my $time = $docobj->get('checkextra', 'alltypes', 2);
isa_ok($time, 'TOML::XS::Timestamp', 'time');
is($time->to_string(), '05:12:23', 'time->to_string()');

my $date = $docobj->get('checkextra', 'alltypes', 3);
isa_ok($date, 'TOML::XS::Timestamp', 'date');
is($date->to_string(), '2026-01-01', 'date->to_string()');

eval { $docobj->get('checkextra', 'alltypes', -1) };
my $err = $@;
like($err, qr<-1>, "negative index to array shows up in error");

eval { $docobj->get('checkextra', 'alltypes', 1, 0, 'extra') };
$err = $@;
ok($err, "extra pointer member under array fails");
like($err, qr</alltypes/1/0>, "JSON pointer is in error");
like($err, qr<integer>, "non-container’s type is in error");

done_testing;
