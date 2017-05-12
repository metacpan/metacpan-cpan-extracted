use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;

$t->connect_ok;
$t->cmd_like(
    "NOOP",
    "tag OK",
);

$t->cmd_ok("LOGIN username password");
$t->cmd_like(
    "NOOP",
    "tag OK",
);

$t->cmd_ok("SELECT INBOX");
$t->cmd_like(
    "NOOP",
    "tag OK",
);

done_testing;

