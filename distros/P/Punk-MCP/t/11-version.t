#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPRpc;

sub negotiate {
    my ($params) = @_;
    my ($s, $bytes, $agreed) = rpc_raw({}, req(1, 'initialize', $params));
    return (jdec($bytes)->{result}{protocolVersion}, $agreed);
}

for my $v (qw(2025-03-26 2025-06-18 2025-11-25)) {
    my ($answer, $agreed) = negotiate({ protocolVersion => $v });
    is($answer, $v, "$v is echoed");
    is($agreed, $v, "$v is what the transport is told was agreed");
}

for my $case (
    [ 'an older version',   { protocolVersion => '2024-11-05' } ],
    [ 'a future version',   { protocolVersion => '2099-01-01' } ],
    [ 'a malformed one',    { protocolVersion => 'latest' } ],
    [ 'a number',           { protocolVersion => 20251125 } ],
    [ 'none at all',        {} ],
) {
    my ($name, $params) = @$case;
    my ($answer, $agreed) = negotiate($params);
    is($answer, '2025-11-25', "$name gets 2025-11-25");
    is($agreed, '2025-11-25', "$name: and that is what was agreed");
}

my ($s, $bytes, $agreed) = rpc_raw({}, req(1, 'initialize'));
is(jdec($bytes)->{result}{protocolVersion}, '2025-11-25', 'no params at all too');

($s, $bytes, $agreed) = rpc_raw({}, req(1, 'ping'));
ok(!defined $agreed, 'only initialize negotiates');

done_testing;
