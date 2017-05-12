use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;

$t->connect_ok;
$t->cmd_like( "STATUS INBOX (MESSAGES)", "tag BAD Log in first" );

$t->cmd_ok("LOGIN username password");

$t->cmd_like( "STATUS INBOX", "tag BAD Not enough options" );
$t->cmd_like( "STATUS INBOX MESSAGES", "tag BAD Wrong second option" );

my $test = sub {
    my @res = split /\r\n/, $t->send_cmd( "STATUS INBOX (@_)" );
    like( pop(@res), qr/^tag OK\b/);
    my $untagged = pop(@res);
    like( $untagged, qr/^\* STATUS "INBOX" \(.*?\)$/, "Got an untagged STATUS response" );
    $untagged =~ qr/\((.*?)\)/;
    return split ' ', $1;
};

my %ret = $test->("MESSAGES");
is_deeply( \%ret, { MESSAGES => 0 },
           "Asked for MESSAGES, got MESSAGES" );

%ret = $test->(qw/MESSAGES UIDNEXT/);
is_deeply( \%ret, { MESSAGES => 0, UIDNEXT => 1000 },
           "Asked for MESSAGES and UIDNEXT, got both" );

%ret = $test->(qw/MESSAGES UIDNEXT UNSEEN/);
is_deeply( \%ret, { MESSAGES => 0, UIDNEXT => 1000, UNSEEN => 0 },
           "Asked for MESSAGES, UIDNEXT and UNSEEN, got all" );

$t->disconnect;

done_testing;
