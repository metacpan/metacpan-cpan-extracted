#use lib "t/lib";
use Test::More tests=>115;

BEGIN{ use_ok( "Net::XMPP3" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP3::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

#------------------------------------------------------------------------------
# iq
#------------------------------------------------------------------------------
my $iq = new Net::XMPP3::IQ();
ok( defined($iq), "new()");
isa_ok( $iq, "Net::XMPP3::IQ");

testScalar($iq, "Error", "error");
testScalar($iq, "ErrorCode", "401");
testJID($iq, "From", "user1", "server1", "resource1");
testScalar($iq, "ID", "id");
testJID($iq, "To", "user2", "server2", "resource2");
testScalar($iq, "Type", "Type");

is( $iq->DefinedChild("__netxmpptest__:child:test"), "", "not DefinedChild - __netxmpptest__:child:test" );
is( $iq->DefinedChild("__netxmpptest__:child:test:two"), "", "not DefinedChild - __netxmpptest__:child:test:two" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xoob = $iq->NewChild("__netxmpptest__:child:test");
ok( defined( $xoob ), "NewX - __netxmpptest__:child:test" );
isa_ok( $xoob, "Net::XMPP3::Stanza" );
is( $iq->DefinedChild(), 1, "DefinedChild" );
is( $iq->DefinedChild("__netxmpptest__:child:test"), 1, "DefinedChild - __netxmpptest__:child:test" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x = $iq->GetChild();
is( $x[0], $xoob, "Is the first child the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xroster = $iq->NewChild("__netxmpptest__:child:test:two");
ok( defined( $xoob ), "NewChild - __netxmpptest__:child:test:two" );
isa_ok( $xoob, "Net::XMPP3::Stanza" );
is( $iq->DefinedChild(), 1, "DefinedChild" );
is( $iq->DefinedChild("__netxmpptest__:child:test"), 1, "DefinedChild - __netxmpptest__:child:test" );
is( $iq->DefinedChild("__netxmpptest__:child:test:two"), 1, "DefinedChild - __netxmpptest__:child:test:two" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x2 = $iq->GetChild();
is( $x2[0], $xoob, "Is the first child the oob?");
is( $x2[1], $xroster, "Is the second child the roster?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x3 = $iq->GetChild("__netxmpptest__:child:test");
is( $#x3, 0, "filter on xmlns - only one child... right?");
is( $x3[0], $xoob, "Is the first child the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x4 = $iq->GetChild("__netxmpptest__:child:test:two");
is( $#x4, 0, "filter on xmlns - only one child... right?");
is( $x4[0], $xroster, "Is the first child the roster?");

is( $iq->DefinedChild("__netxmpptest__:child:test:three"), "", "not DefinedChild - __netxmpptest__:child:test:three" );

#------------------------------------------------------------------------------
# Query
#------------------------------------------------------------------------------
my $child = $iq->GetQuery();
is($child, $xoob, "Is the query xoob?");

#------------------------------------------------------------------------------
# iq
#------------------------------------------------------------------------------
my $iq2 = new Net::XMPP3::IQ();
ok( defined($iq2), "new()");
isa_ok( $iq2, "Net::XMPP3::IQ");

#------------------------------------------------------------------------------
# defined
#------------------------------------------------------------------------------
is( $iq2->DefinedError(), '', "error not defined" );
is( $iq2->DefinedErrorCode(), '', "errorcode not defined" );
is( $iq2->DefinedFrom(), '', "from not defined" );
is( $iq2->DefinedID(), '', "id not defined" );
is( $iq2->DefinedTo(), '', "to not defined" );
is( $iq2->DefinedType(), '', "type not defined" );

#------------------------------------------------------------------------------
# set it
#------------------------------------------------------------------------------
$iq2->SetIQ(error=>"error",
            errorcode=>"401",
            from=>"user1\@server1/resource1",
            id=>"id",
            to=>"user2\@server2/resource2",
            type=>"type");

testPostScalar($iq2, "Error", "error");
testPostScalar($iq2, "ErrorCode", "401");
testPostJID($iq2, "From", "user1", "server1", "resource1");
testPostScalar($iq2, "ID", "id");
testPostJID($iq2, "To", "user2", "server2", "resource2");
testPostScalar($iq2, "Type", "type");

is( $iq2->GetXML(), "<iq from='user1\@server1/resource1' id='id' to='user2\@server2/resource2' type='type'><error code='401'>error</error></iq>", "Full iq");

#------------------------------------------------------------------------------
# Reply
#------------------------------------------------------------------------------
my $query = $iq2->NewChild("jabber:iq:roster");

my $reply = $iq2->Reply();
isa_ok($reply,"Net::XMPP3::IQ");

testPostJID($reply, "From", "user2", "server2", "resource2");
testPostScalar($reply, "ID", "id");
testPostJID($reply, "To", "user1", "server1", "resource1");
testPostScalar($reply, "Type", "result");

is($reply->GetXML(),"<iq from='user2\@server2/resource2' id='id' to='user1\@server1/resource1' type='result'><query xmlns='jabber:iq:roster'/></iq>","Reply - GetXML()");

#------------------------------------------------------------------------------
# Remove it
#------------------------------------------------------------------------------
testRemove($iq2, "ErrorCode");
testRemove($iq2, "Error");
testRemove($iq2, "From");
testRemove($iq2, "ID");
testRemove($iq2, "To");
testRemove($iq2, "Type");

$iq2->RemoveChild("jabber:iq:roster");

is( $iq2->GetXML(), "<iq/>", "Empty iq");

