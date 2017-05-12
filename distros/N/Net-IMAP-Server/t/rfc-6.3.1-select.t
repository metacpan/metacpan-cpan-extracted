use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;
for my $cmd (qw/SELECT EXAMINE/) {
    $t->connect_ok;

    $t->cmd_like( "$cmd INBOX" => "tag BAD Log in first" );

    $t->cmd_ok("LOGIN username password");

    $t->cmd_like( "$cmd" => "tag BAD Not enough options" );
    $t->cmd_like( "$cmd foo bar" => "tag BAD Too many options" );
    $t->cmd_like( "$cmd broken" => "tag NO Mailbox does not exist" );

    # Can't do a FETCH before selecting/examining
    $t->cmd_like( "FETCH 1:* UID" => "tag BAD Select a mailbox first" );

    # Check that we have all of the simple requirements of the response
    my @res = split /\r\n/, $t->send_cmd( "$cmd INBOX" );
    # The tagged response has to be last
    my $mode = ($cmd eq "SELECT") ? "READ-WRITE" : "READ-ONLY";
    like( pop(@res), qr/^tag OK \[$mode\]/);
    # But everything else can be in any order
    is((grep /^\* FLAGS \(\\\S+(?:\s+\\\S+)*\)/, @res), 1, "Has FLAGS");
    is((grep /^\* \d+ EXISTS\b/, @res), 1, "Has EXISTS");
    is((grep /^\* \d+ RECENT\b/, @res), 1, "Has RECENT");
    is((grep /^\* OK \[UNSEEN \d+\]/, @res), 1, "Has UNSEEN");
    is((grep /^\* OK \[PERMANENTFLAGS \(\\\S+(?:\s+\\\S+)*\)\]/, @res), 1,
       "Has PERMANENTFLAGS");
    is((grep /^\* OK \[UIDNEXT \d+\]/, @res), 1, "Has UIDNEXT");
    is((grep /^\* OK \[UIDVALIDITY \d+\]/, @res), 1, "Has UIDVALIDITY");

    # Fetch works now
    $t->cmd_like( "FETCH 1:* UID" => "tag OK FETCH COMPLETED" );

    # Selecting/examining a bogus mailbox unselects the connection
    $t->cmd_like( "$cmd broken" => "tag NO Mailbox does not exist" );
    $t->cmd_like( "FETCH 1:* UID" => "tag BAD Select a mailbox first" );

    # Test inbox case sensitivity
    $t->cmd_ok( "$cmd INBOX" );
    $t->cmd_ok( "$cmd inbox" );
    my $res = $t->cmd_ok( "$cmd InBoX" );

    # Check that FLAGS includes the expected
    my %flags;
    ok($res =~ /^\* FLAGS \((\\\S+(?:\s+\\\S+)*)\)/m, "Found flags");
    $flags{$_}++ for split ' ', $1;
    ok(delete $flags{$_}, "Has $_ flag")
        for qw/\Answered \Flagged \Deleted \Seen \Draft/;
    ok(!$flags{'\Recent'}, 'Lacks \Recent flag');

    # Check that PERMANENTFLAGS includes the expected
    %flags = ();
    ok($res =~ /^\* OK \[PERMANENTFLAGS \((\\\S+(?:\s+\\\S+)*)\)\]/m, "Found permanentflags");
    $flags{$_}++ for split ' ', $1;
    ok(delete $flags{$_}, "Has $_ permanentflag")
        for qw/\Answered \Flagged \Deleted \Seen \Draft/;
    ok(!$flags{'\Recent'}, 'Lacks \Recent permanentflag');

    $t->disconnect;
}


done_testing;
