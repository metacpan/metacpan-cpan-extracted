use lib "t/lib";
use Test::More tests=>117;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

#------------------------------------------------------------------------------
# presence
#------------------------------------------------------------------------------
my $presence = new Net::Jabber::Presence();
ok( defined($presence), "new()");
isa_ok( $presence, "Net::Jabber::Presence");
isa_ok( $presence, "Net::XMPP::Presence");

testScalar($presence, "Error", "error");
testScalar($presence, "ErrorCode", "401");
testJID($presence, "From", "user1", "server1", "resource1");
testScalar($presence, "ID", "id");
testScalar($presence, "Priority", "priority");
testScalar($presence, "Show", "show");
testScalar($presence, "Status", "status");
testJID($presence, "To", "user2", "server2", "resource2");
testScalar($presence, "Type", "Type");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xoob = $presence->NewChild("jabber:x:oob");
ok( defined( $xoob ), "NewChild - jabber:x:oob" );
isa_ok( $xoob, "Net::XMPP::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x = $presence->GetChild();
is( $x[0], $xoob, "Is the first x the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xroster = $presence->NewChild("jabber:x:roster");
ok( defined( $xoob ), "NewChild - jabber:x:roster" );
isa_ok( $xoob, "Net::XMPP::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x2 = $presence->GetChild();
is( $x2[0], $xoob, "Is the first x the oob?");
is( $x2[1], $xroster, "Is the second x the roster?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x3 = $presence->GetChild("jabber:x:oob");
is( $#x3, 0, "filter on xmlns - only one x... right?");
is( $x3[0], $xoob, "Is the first x the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x4 = $presence->GetChild("jabber:x:roster");
is( $#x4, 0, "filter on xmlns - only one x... right?");
is( $x4[0], $xroster, "Is the first x the roster?");

#------------------------------------------------------------------------------
# presence
#------------------------------------------------------------------------------
my $presence2 = new Net::Jabber::Presence();
ok( defined($presence2), "new()");
isa_ok( $presence2, "Net::Jabber::Presence");

#------------------------------------------------------------------------------
# defined
#------------------------------------------------------------------------------
is( $presence2->DefinedError(), '', "error not defined" );
is( $presence2->DefinedErrorCode(), '', "errorcode not defined" );
is( $presence2->DefinedFrom(), '', "from not defined" );
is( $presence2->DefinedID(), '', "id not defined" );
is( $presence2->DefinedPriority(), '', "priority not defined" );
is( $presence2->DefinedShow(), '', "show not defined" );
is( $presence2->DefinedStatus(), '', "status not defined" );
is( $presence2->DefinedTo(), '', "to not defined" );
is( $presence2->DefinedType(), '', "type not defined" );

#------------------------------------------------------------------------------
# set it
#------------------------------------------------------------------------------
$presence2->SetPresence(error=>"error",
                        errorcode=>"401",
                        from=>"user1\@server1/resource1",
                        id=>"id",
                        priority=>"priority",
                        show=>"show",
                        status=>"status",
                        to=>"user2\@server2/resource2",
                        type=>"type");

testPostScalar($presence2, "Error", "error");
testPostScalar($presence2, "ErrorCode", "401");
testPostJID($presence2, "From", "user1", "server1", "resource1");
testPostScalar($presence2, "ID", "id");
testPostScalar($presence2, "Priority", "priority");
testPostScalar($presence2, "Show", "show");
testPostScalar($presence2, "Status", "status");
testPostJID($presence2, "To", "user2", "server2", "resource2");
testPostScalar($presence2, "Type", "type");


#------------------------------------------------------------------------------
# Reply
#------------------------------------------------------------------------------
my $reply2 = $presence2->Reply();
ok( defined($reply2), "new()");
isa_ok( $reply2, "Net::Jabber::Presence");
isa_ok( $reply2, "Net::XMPP::Presence");

testPostJID($reply2, "From", "user2", "server2", "resource2");
testPostScalar($reply2, "ID", "id");
testPostJID($reply2, "To", "user1", "server1", "resource1");

is( $reply2->GetXML(), "<presence from='user2\@server2/resource2' id='id' to='user1\@server1/resource1'/>", "GetXML()");

