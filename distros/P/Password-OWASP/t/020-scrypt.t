use strict;
use warnings;
use Test::More 0.96;

use_ok("Password::OWASP");

use Password::OWASP::Scrypt;
use Authen::Passphrase::Scrypt;

my $pwo = Password::OWASP::Scrypt->new();

isa_ok($pwo, 'Password::OWASP::Scrypt');

my $crypted = $pwo->crypt_password('demo');

ok(
    $pwo->check_password('demo', $crypted),
    "demo password is correct"
);

ok(
    !$pwo->check_password('Demo', $crypted),
    ".. and Demo isn't"
);

my $ppr = Authen::Passphrase::Scrypt->new(
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

$pwo = Password::OWASP::Scrypt->new(
    update_method => sub {
        my ($password) = shift;
        $updated_password = $password;
        return 1;
    },
);

$pwo->check_password('demo', '{CLEARTEXT}demo');

isnt($updated_password, undef, "Changed our password on checking");

done_testing;
