use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;

# Non-SSL
$t->connect_ok( "Non-SSL connection OK",
    Class => "IO::Socket::INET",
    PeerPort => $t->PORT,
);
ok($t->connected, "Is connected");
$t->cmd_like(
    "LOGOUT",
    "* BYE",
    "tag OK",
);
ok(!$t->connected, "Is now disconnected");

# SSL connection
$t->connect_ok;
ok($t->connected, "Is connected");
$t->cmd_like(
    "LOGOUT",
    "* BYE",
    "tag OK",
);
ok(!$t->connected, "Is now disconnected");

# Logged in
$t->connect_ok;
ok($t->connected, "Is now connected");
$t->cmd_ok("LOGIN username password");
ok($t->connected, "Still connected after LOGIN");
$t->cmd_like(
    "LOGOUT",
    "* BYE",
    "tag OK",
);
ok(!$t->connected, "Is now disconnected");

# And selected
$t->connect_ok;
ok($t->connected, "Is now connected");
$t->cmd_ok("LOGIN username password");
ok($t->connected, "Still connected after LOGIN");
$t->cmd_ok("SELECT INBOX");
ok($t->connected, "Still connected after SELECT");
$t->cmd_like(
    "LOGOUT",
    "* BYE",
    "tag OK",
);
ok(!$t->connected, "Is now disconnected");

done_testing;
