use Test::More tests => 23;
use strict;
$^W = 1;

use Return::Value;

my $ret = Return::Value->new;
isa_ok $ret, 'Return::Value';
ok ! $ret->bool, 'false';
is $ret->errno, undef, 'errno 0';
is $ret->string, "", 'empty string';
ok ! $ret->data, 'no data';
is scalar(keys %{$ret->prop}), 0, 'no properties';

$ret = Return::Value->new(
    type   => 'success',
    errno  => 128,
    string => 'string',
    data   => [ 'one' ],
    prop   => { one => 1 },
);

isa_ok $ret, 'Return::Value';
ok $ret->bool, 'true';
is $ret->errno, 128, 'errno 128';
is $ret->errno(undef), undef, 'errno undef';
is $ret->errno,        undef, 'errno still undef';
is $ret->string, 'string', 'string is string';
is ref($ret->data), 'ARRAY', 'data array ref';
is scalar(@{$ret->data}), 1, 'one element in data';
is ref($ret->prop), 'HASH', 'hash in prop';
is $ret->prop->{one}, 1, 'one prop set';

$ret->type('failure');
ok ! $ret->bool, 'now false';
is $ret->prop('one'), 1, 'object access for one';
is $ret->prop(two => 2), 2, 'prop create for two';
is $ret->errno(10), 10, 'set errno with method';
is $ret->type(), 'failure', 'type is currently failure';
is $ret->type("success"), 'success', 'set type with method';

eval { $ret->type("top secret"); };
like($@, qr/invalid result type/, "death on unknown type");
