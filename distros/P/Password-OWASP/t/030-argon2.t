use strict;
use warnings;
use Test::More 0.96;

use_ok("Password::OWASP");

use Password::OWASP::Argon2;
use Authen::Passphrase::Argon2;

my $pwo = Password::OWASP::Argon2->new(
    hashing => 'sha512',
);

isa_ok($pwo, 'Password::OWASP::Argon2');

my $crypted = $pwo->crypt_password('demo');

ok(
    $pwo->check_password('demo', $crypted),
    "demo password is correct"
);

ok(
    !$pwo->check_password('Demo', $crypted),
    ".. and Demo isn't"
);

my $none = Password::OWASP::Argon2->new(
    hashing => 'none',
);

ok(
    $none->check_password('demo', $crypted),
    "Default change to none supports old sha512 default"
);

my $ppr = Authen::Passphrase::Argon2->new(
    cost        => 2,
    salt_random => 1,
    passphrase  => 'demo'
);

$crypted = $ppr->as_rfc2307;

ok(
    $pwo->check_password('demo', $crypted),
    ".. and the legacy is also correct"
);

ok(
    !$pwo->check_password('Demo', $crypted),
    ".. and Demo isn't for legacy"
);


my $unencrypted = '{CLEARTEXT}demo';

ok(
    $pwo->check_password('demo', $unencrypted),
    ".. and an uncrypted password is also also correct for legacy"
);

my $updated_password;

$pwo = Password::OWASP::Argon2->new(
    hashing => 'sha512',
    cost => 4,
    update_method => sub {
        my ($password) = shift;
        $updated_password = $password;
        return 1;
    },
);

is($pwo->cost, 4, "Changed the cost to 4");

$pwo->check_password('demo', '{CLEARTEXT}demo');

isnt($updated_password, undef, "Changed our password on checking");

done_testing;
