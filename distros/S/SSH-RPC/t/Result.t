use lib '../lib';

use strict;
use Test::More;

plan tests => 13;


use_ok('SSH::RPC::Result');
my $result = SSH::RPC::Result->new({
    status      => 200,
    response    => 'Buxton',
    version     => 1.2
    });
is($result->getStatus, 200, "getStatus()");
is($result->getError, undef, "!getError()");
ok($result->isSuccess, 'isSuccess()');
is($result->getShellVersion, 1.2, 'getShellVersion()');
is($result->getResponse, 'Buxton', 'getResponse() as scalar');

$result = SSH::RPC::Result->new({
    status      => 400,
    error       => 'Boggs'
    });
is($result->getStatus, 400, "getStatus() w/ error");
is($result->getError, "Boggs", "getError()");
ok(!$result->isSuccess, "!isSuccess()");

$result = SSH::RPC::Result->new({
    status      => 200,
    response       => {this=>"that", one=>1}
    });
is(ref $result->getResponse, 'HASH', "getResponse() w/ hashref");
is($result->getResponse->{this}, 'that', "getResponse() w/ hashref get value");

$result = SSH::RPC::Result->new({
    status      => 200,
    response       => [qw(red green blue)]
    });
is(ref $result->getResponse, 'ARRAY', "getResponse() w/ arrayref");
is($result->getResponse->[1], 'green', "getResponse() w/ arrayref get value");



