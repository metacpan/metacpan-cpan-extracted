use strict;
use warnings;
use Test::More tests => 2;
use Test::Deep;

use MooseX::Types::Email qw/EmailMessages/;

my $valid = <<'VALID';
From: example@example.com
To: example@example.com
Subject: test
Date: Tue Oct 20 21:57:31 2009

a body
VALID

my $es = Email::Simple->new($valid);

ok(
    EmailMessages->check([ $es ]),
    'example list of email(s) is an ok list of emails',
);

like(
    EmailMessages->validate([ $valid ]),
    qr/something Email::Abstract recognizes/,
    'validation fails, as list of strings are not valid email bodies',
);

