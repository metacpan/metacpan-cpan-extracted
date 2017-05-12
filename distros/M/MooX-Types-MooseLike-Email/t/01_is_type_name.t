use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

use MooX::Types::MooseLike::Email qw/:all/;

my $text = <<'TEXT';
From: example@example.com
To: example@example.com
Subject: test
Date: Thu Jan 10 07:51:30 2013

Hello World
TEXT

my $msg = Email::Simple->new($text);

ok (is_EmailAddress('hoge@example.com'), 'is_EmailAddress');
ok (is_EmailAddressLoose('hoge..@example.com'), 'is_EmailAddressLoose');
ok (is_EmailMessage($msg), 'is_EmailMessage');
