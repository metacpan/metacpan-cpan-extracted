use strict;
use Test::More 0.98;

use String::Secret;

my $secret = String::Secret->new('mysecret');
isa_ok $secret, 'String::Secret';
unlike "$secret", qr/mysecret/, 'do not include secret';
is $secret->unwrap, 'mysecret', 'unwrap result is same as secret';

subtest 'serializable' => sub {
    my $serializable_secret = $secret->to_serializable();
    isa_ok $serializable_secret, 'String::Secret::Serializable';
    unlike "$serializable_secret", qr/mysecret/, 'do not include secret';
    is $serializable_secret->unwrap, 'mysecret', 'unwrap result is same as secret';
};

subtest '$DISABLE_MASK = 1' => sub {
    local $String::Secret::DISABLE_MASK = 1;
    is $secret, 'mysecret', 'do not mask secret';
    is $secret->unwrap, 'mysecret', 'unwrap result is same as secret';
};

done_testing;

