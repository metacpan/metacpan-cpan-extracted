use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;

# SSL allows auth
$t->connect_ok;
my ($cap) = $t->cmd_like(
    "CAPABILITY",
    "* CAPABILITY",
    "tag OK",
);

like($cap, qr/\bIMAP4rev1\b/, "Advertises IMAP4rev1");
like($cap, qr/\bAUTH=PLAIN\b/, "Advertises AUTH=PLAIN over SSL");
unlike($cap, qr/\bSTARTTLS\b/, "TLS is not advertized over SSL");
unlike($cap, qr/\bLOGINDISABLED\b/, "Login is not DISABLED over SSL");

# Try over simple TCP
$t->connect_ok( "Non-SSL connection OK",
    Class => "IO::Socket::INET",
    PeerPort => $t->PORT,
);
($cap) = $t->cmd_like(
    "CAPABILITY",
    "* CAPABILITY",
    "tag OK",
);
like($cap, qr/\bIMAP4rev1\b/, "Advertises IMAP4rev1");
unlike($cap, qr/\bAUTH=PLAIN\b/, "Does not advertize AUTH=PLAIN over TCP");
like($cap, qr/\bSTARTTLS\b/, "TLS is advertized over TCP");
like($cap, qr/\bLOGINDISABLED\b/, "LOGINDISABLED over TCP");

# Start up TLS and try again
$t->cmd_like("STARTTLS" => "tag OK");
$t->start_tls_ok;
($cap) = $t->cmd_like(
    "CAPABILITY",
    "* CAPABILITY",
    "tag OK",
);
like($cap, qr/\bIMAP4rev1\b/, "Advertises IMAP4rev1");
like($cap, qr/\bAUTH=PLAIN\b/, "Advertises AUTH=PLAIN over TLS");
unlike($cap, qr/\bSTARTTLS\b/, "TLS is not advertized over TLS");
unlike($cap, qr/\bLOGINDISABLED\b/, "Login is not DISABLED over TLS");

# See what changes once we're logged in
$t->cmd_ok("LOGIN username password", "Logged in");
($cap) = $t->cmd_like(
    "CAPABILITY",
    "* CAPABILITY",
    "tag OK",
);
like($cap, qr/\bIMAP4rev1\b/, "Advertises IMAP4rev1");
unlike($cap, qr/\bAUTH=PLAIN\b/, "No longer advertises AUTH after login");
unlike($cap, qr/\bSTARTTLS\b/, "TLS is not advertized over TLS");
unlike($cap, qr/\bLOGINDISABLED\b/, "Login is not DISABLED over TLS");

done_testing;
