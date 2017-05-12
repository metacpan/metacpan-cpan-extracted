# This -*- perl -*- code tests the message splitting

# $Id: split.t,v 1.4 2003/01/03 02:03:34 lem Exp $

use Test::More tests => 16;
use SMS::Handler::Utils;

my $msg;
my $body;

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{.ACCOUNT foo bar\nmessage}
					   );

is($msg, ".ACCOUNT foo bar");
is($body, "message");

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{.ACCOUNT foo bar  message}
					   );

is($msg, ".ACCOUNT foo bar");
is($body, "message");

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{.ACCOUNT bar baz}
					   );

is($msg, ".ACCOUNT bar baz");
is($body, "");

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{\n}
					   );

is($msg, "");
is($body, "");

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{.A foo bar\nmessage\nanother}
					   );

is($msg, ".A foo bar");
is($body, "message\nanother");

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{.A foo bar  message\nanother}
					   );

is($msg, ".A foo bar");
is($body, "message\nanother");

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{\n\n}
					   );

is($msg, "");
is($body, "\n");

($msg, $body) = SMS::Handler::Utils::Split(
					   qq{  }
					   );

is($msg, "");
is($body, "");

