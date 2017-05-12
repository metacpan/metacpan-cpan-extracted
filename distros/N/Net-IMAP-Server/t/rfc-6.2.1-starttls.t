use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;

# Invalid over SSL
$t->connect_ok;
$t->cmd_like("STARTTLS" => "tag NO STARTTLS is disabled");
$t->cmd_ok("LOGOUT");

# Connect over TCP
$t->connect_ok( "Non-SSL connection OK",
    Class => "IO::Socket::INET",
    PeerPort => $t->PORT,
);

$t->cmd_like("STARTTLS" => "tag OK");
$t->start_tls_ok;

# Check that you can't STARTTLS twice
$t->cmd_like("STARTTLS" => "tag NO STARTTLS is disabled");

# Check that it fails after auth
$t->cmd_ok("LOGIN username password");
$t->cmd_like("STARTTLS" => "tag BAD Already logged in");

done_testing;
