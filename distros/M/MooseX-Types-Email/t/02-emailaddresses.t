use strict;
use warnings;
use Test::More tests => 3;
use Test::Deep;

use MooseX::Types::Email qw/EmailAddresses/;

ok(
    EmailAddresses->check([ 'bobtfish@bobtfish.net', 'foo@bar.com' ]),
    'bobtfish@bobtfish.net and foo@bar.com are an ok list of email addresses',
);

like(
    EmailAddresses->validate([ 'foo@bar.com', 'wob' ]),
    qr/be an arrayref of valid e-mail addresses/,
    'validation fails, as "wob" is not a valid email',
);

cmp_deeply(
    EmailAddresses->coerce('foo@bar.com'),
    [ 'foo@bar.com' ],
    'a single email address can be coerced to a list of addresses',
);

