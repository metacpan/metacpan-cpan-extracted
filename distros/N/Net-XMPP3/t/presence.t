use lib "t/lib";
use Test::More tests=>132;

BEGIN{ use_ok( "Net::XMPP3" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP3::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

#------------------------------------------------------------------------------
# presence
#------------------------------------------------------------------------------
my $presence = new Net::XMPP3::Presence();
ok( defined($presence), "new()");
isa_ok( $presence, "Net::XMPP3::Presence");

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
my $xoob = $presence->NewChild("__netxmpptest__:child:test");
ok( defined( $xoob ), "NewX - __netxmpptest__:child:test" );
isa_ok( $xoob, "Net::XMPP3::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x = $presence->GetChild();
is( $x[0], $xoob, "Is the first x the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xroster = $presence->NewChild("__netxmpptest__:child:test:two");
ok( defined( $xoob ), "NewX - __netxmpptest__:child:test:two" );
isa_ok( $xoob, "Net::XMPP3::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x2 = $presence->GetChild();
is( $x2[0], $xoob, "Is the first child test?");
is( $x2[1], $xroster, "Is the second child test two?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x3 = $presence->GetChild("__netxmpptest__:child:test");
is( $#x3, 0, "filter on xmlns - only one child... right?");
is( $x3[0], $xoob, "Is the first child the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x4 = $presence->GetChild("__netxmpptest__:child:test:two");
is( $#x4, 0, "filter on xmlns - only one x... right?");
is( $x4[0], $xroster, "Is the first x the roster?");

ok( $presence->DefinedChild(), "DefinedChild - yes");
ok( $presence->DefinedChild("__netxmpptest__:child:test:two"), "DefinedChild - __netxmpptest__:child:test:two - yes");
ok( $presence->DefinedChild("__netxmpptest__:child:test"), "DefinedChild - __netxmpptest__:child:test - yes");
ok( !$presence->DefinedChild("foo:bar"), "DefinedChild - foo:bar - no");

#------------------------------------------------------------------------------
# presence
#------------------------------------------------------------------------------
my $presence2 = new Net::XMPP3::Presence();
ok( defined($presence2), "new()");
isa_ok( $presence2, "Net::XMPP3::Presence");

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

is( $presence2->GetXML(), "<presence from='user1\@server1/resource1' id='id' to='user2\@server2/resource2' type='type'><error code='401'>error</error><priority>priority</priority><show>show</show><status>status</status></presence>", "Full presence");

#------------------------------------------------------------------------------
# Reply
#------------------------------------------------------------------------------
my $reply = $presence2->Reply();
isa_ok($reply,"Net::XMPP3::Presence");

testPostJID($reply, "From", "user2", "server2", "resource2");
testPostScalar($reply, "ID", "id");
testPostJID($reply, "To", "user1", "server1", "resource1");

is($reply->GetXML(),"<presence from='user2\@server2/resource2' id='id' to='user1\@server1/resource1'/>","Reply - GetXML()");


#------------------------------------------------------------------------------
# Remove it
#------------------------------------------------------------------------------
testRemove($presence2, "ErrorCode");
testRemove($presence2, "Error");
testRemove($presence2, "From");
testRemove($presence2, "ID");
testRemove($presence2, "Priority");
testRemove($presence2, "Show");
testRemove($presence2, "Status");
testRemove($presence2, "To");
testRemove($presence2, "Type");

is( $presence2->GetXML(), "<presence/>", "Empty presence");

