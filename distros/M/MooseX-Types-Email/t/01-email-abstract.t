use strict;
use warnings;
use Test::More tests => 2;

use MooseX::Types::Email qw/EmailMessage/;

my $valid = <<'VALID';
From: example@example.com
To: example@example.com
Subject: test
Date: Tue Oct 20 21:57:31 2009

a body
VALID

my $es = Email::Simple->new($valid);

ok(
    EmailMessage->check($es),
    'example email is an ok email',
);

like(
    EmailMessage->validate($valid),
    qr/something Email::Abstract recognizes/,
    'validation fails, as string is not a valid email body',
);

