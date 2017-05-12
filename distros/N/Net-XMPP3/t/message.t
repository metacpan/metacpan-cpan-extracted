use lib "t/lib";
use Test::More tests=>136;

BEGIN{ use_ok( "Net::XMPP3" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP3::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

#------------------------------------------------------------------------------
# message
#------------------------------------------------------------------------------
my $message = new Net::XMPP3::Message();
ok( defined($message), "new()");
isa_ok( $message, "Net::XMPP3::Message");

testScalar($message, "Body", "body");
testScalar($message, "Error", "error");
testScalar($message, "ErrorCode", "401");
testJID($message, "From", "user1", "server1", "resource1");
testScalar($message, "ID", "id");
testScalar($message, "Subject", "subject");
testScalar($message, "Thread", "thread");
testJID($message, "To", "user2", "server2", "resource2");
testScalar($message, "Type", "Type");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xoob = $message->NewChild("__netxmpptest__:child:test");
ok( defined( $xoob ), "NewX - __netxmpptest__:child:test" );
isa_ok( $xoob, "Net::XMPP3::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x = $message->GetChild();
is( $x[0], $xoob, "Is the first x the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xroster = $message->NewChild("__netxmpptest__:child:test:two");
ok( defined( $xoob ), "NewX - __netxmpptest__:child:test:two" );
isa_ok( $xoob, "Net::XMPP3::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x2 = $message->GetChild();
is( $x2[0], $xoob, "Is the first child test?");
is( $x2[1], $xroster, "Is the second child test two?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x3 = $message->GetChild("__netxmpptest__:child:test");
is( $#x3, 0, "filter on xmlns - only one child... right?");
is( $x3[0], $xoob, "Is the first child the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x4 = $message->GetChild("__netxmpptest__:child:test:two");
is( $#x4, 0, "filter on xmlns - only one x... right?");
is( $x4[0], $xroster, "Is the first x the roster?");

ok( $message->DefinedChild(), "DefinedChild - yes");
ok( $message->DefinedChild("__netxmpptest__:child:test:two"), "DefinedChild - __netxmpptest__:child:test:two - yes");
ok( $message->DefinedChild("__netxmpptest__:child:test"), "DefinedChild - __netxmpptest__:child:test - yes");
ok( !$message->DefinedChild("foo:bar"), "DefinedChild - foo:bar - no");

#------------------------------------------------------------------------------
# message
#------------------------------------------------------------------------------
my $message2 = new Net::XMPP3::Message();
ok( defined($message2), "new()");
isa_ok( $message2, "Net::XMPP3::Message");

#------------------------------------------------------------------------------
# defined
#------------------------------------------------------------------------------
is( $message2->DefinedBody(), '', "body not defined" );
is( $message2->DefinedError(), '', "error not defined" );
is( $message2->DefinedErrorCode(), '', "errorcode not defined" );
is( $message2->DefinedFrom(), '', "from not defined" );
is( $message2->DefinedID(), '', "id not defined" );
is( $message2->DefinedSubject(), '', "subject not defined" );
is( $message2->DefinedThread(), '', "thread not defined" );
is( $message2->DefinedTo(), '', "to not defined" );
is( $message2->DefinedType(), '', "type not defined" );

#------------------------------------------------------------------------------
# set it
#------------------------------------------------------------------------------
$message2->SetMessage(body=>"body",
                      error=>"error",
                      errorcode=>"401",
                      from=>"user1\@server1/resource1",
                      id=>"id",
                      subject=>"subject",
                      thread=>"thread",
                      to=>"user2\@server2/resource2",
                      type=>"type");

testPostScalar($message2, "Body", "body");
testPostScalar($message2, "Error", "error");
testPostScalar($message2, "ErrorCode", "401");
testPostJID($message2, "From", "user1", "server1", "resource1");
testPostScalar($message2, "ID", "id");
testPostScalar($message2, "Subject", "subject");
testPostScalar($message2, "Thread", "thread");
testPostJID($message2, "To", "user2", "server2", "resource2");
testPostScalar($message2, "Type", "type");

is( $message2->GetXML(), "<message from='user1\@server1/resource1' id='id' to='user2\@server2/resource2' type='type'><body>body</body><error code='401'>error</error><subject>subject</subject><thread>thread</thread></message>", "Full message");

#------------------------------------------------------------------------------
# Reply
#------------------------------------------------------------------------------
testRemove($message2, "Type");

my $reply = $message2->Reply();
isa_ok($reply,"Net::XMPP3::Message");

testPostJID($reply, "From", "user2", "server2", "resource2");
testPostScalar($reply, "ID", "id");
testPostScalar($reply, "Subject", "re: subject");
testPostScalar($reply, "Thread", "thread");
testPostJID($reply, "To", "user1", "server1", "resource1");

is( $reply->GetXML(), "<message from='user2\@server2/resource2' id='id' to='user1\@server1/resource1'><subject>re: subject</subject><thread>thread</thread></message>", "Reply - GetXML()" );

#------------------------------------------------------------------------------
# Remove it
#------------------------------------------------------------------------------
testRemove($message2, "Body");
testRemove($message2, "ErrorCode");
testRemove($message2, "Error");
testRemove($message2, "From");
testRemove($message2, "ID");
testRemove($message2, "Subject");
testRemove($message2, "Thread");
testRemove($message2, "To");

is( $message2->GetXML(), "<message/>", "Empty message");

