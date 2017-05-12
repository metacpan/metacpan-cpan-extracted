use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;

# Connect over SSL
$t->connect_ok;

# Try a wrong password
$t->cmd_like("LOGIN username wrong", "tag NO");

# The right password works
$t->cmd_like("LOGIN username password", "tag OK");

# You can't auth if you already are
$t->cmd_like("LOGIN username password", "tag BAD");
$t->cmd_ok("LOGOUT");

# You can't auth over non-SSL
$t->connect_ok( "Non-SSL connection OK",
    Class => "IO::Socket::INET",
    PeerPort => $t->PORT,
);
$t->cmd_like("LOGIN username password", "* BAD [ALERT]", "tag NO");

# But once you STARTTLS, you're fine
$t->cmd_like("STARTTLS" => "tag OK");
$t->start_tls_ok;
$t->cmd_like("LOGIN username password", "tag OK");

done_testing;
