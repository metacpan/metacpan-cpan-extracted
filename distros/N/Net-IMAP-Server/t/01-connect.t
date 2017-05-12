use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;

# Check Non-SSL connection
$t->connect_ok( "Non-SSL connection OK",
    Class => "IO::Socket::INET",
    PeerPort => $t->PORT,
);

# And STARTTLS
$t->cmd_like("STARTTLS" => "tag OK");
$t->start_tls_ok;
$t->disconnect;

# And the default SSL
$t->connect_ok( "SSL connection OK" );
$t->disconnect;

# Check multiple concurrent connections
$t->as("A")->connect_ok(    "First client" );
$t->as("A")->cmd_ok("NOOP", "First client can run commands" );
$t->as("B")->connect_ok(    "Second client" );
$t->as("A")->cmd_ok("NOOP", "First client can still run commands" );
$t->as("B")->cmd_ok("NOOP", "So can the second" );
$t->as("B")->disconnect;
$t->as("A")->cmd_ok("NOOP", "After the second disconnects, the first is still there" );
$t->as("A")->disconnect;


done_testing();
