use strict;
use warnings;
use Test::More tests => 3;

use MooseX::Types::Email qw/EmailAddress/;

ok(
    EmailAddress->check('bobtfish@bobtfish.net'),
    'bobtfish@bobtfish.net is an ok email',
);

like(
    EmailAddress->validate('wob'),
    qr/be a valid e-mail/,
    'validation fails, as "wob" is not a valid email',
);

ok(
    EmailAddress->check("bobtfish\@bobtfish.net\n"),
    'bobtfish@bobtfish.net<newline> is an ok email',
);

