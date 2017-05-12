use lib "t/lib";
use Test::More tests=>126;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

#------------------------------------------------------------------------------
# message
#------------------------------------------------------------------------------
my $message = new Net::Jabber::Message();
ok( defined($message), "new()");
isa_ok( $message, "Net::Jabber::Message");
isa_ok( $message, "Net::XMPP::Message");

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
my $xoob = $message->NewChild("jabber:x:oob");
ok( defined( $xoob ), "NewChild - jabber:x:oob" );
isa_ok( $xoob, "Net::XMPP::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x = $message->GetChild();
is( $x[0], $xoob, "Is the first x the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my $xroster = $message->NewChild("jabber:x:roster");
ok( defined( $xroster ), "NewChild - jabber:x:roster" );
isa_ok( $xroster, "Net::XMPP::Stanza" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x2 = $message->GetChild();
is( $x2[0], $xoob, "Is the first x the oob?");
is( $x2[1], $xroster, "Is the second x the roster?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x3 = $message->GetChild("jabber:x:oob");
is( $#x3, 0, "filter on xmlns - only one x... right?");
is( $x3[0], $xoob, "Is the first x the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x4 = $message->GetChild("jabber:x:roster");
is( $#x4, 0, "filter on xmlns - only one x... right?");
is( $x4[0], $xroster, "Is the first x the roster?");

ok( $message->DefinedChild(), "DefinedX - yes");
ok( $message->DefinedChild("jabber:x:roster"), "DefinedX - jabber:x:roster - yes");
ok( $message->DefinedChild("jabber:x:oob"), "DefinedX - jabber:x:oob - yes");
ok( !$message->DefinedChild("foo:bar"), "DefinedX - foo:bar - no");

#------------------------------------------------------------------------------
# message
#------------------------------------------------------------------------------
my $message2 = new Net::Jabber::Message();
ok( defined($message2), "new()");
isa_ok( $message2, "Net::Jabber::Message");
isa_ok( $message2, "Net::XMPP::Message");

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


#------------------------------------------------------------------------------
# Reply
#------------------------------------------------------------------------------
my $reply2 = $message2->Reply();
ok( defined($reply2), "new()");
isa_ok( $reply2, "Net::Jabber::Message");
isa_ok( $reply2, "Net::XMPP::Message");

testPostJID($reply2, "From", "user2", "server2", "resource2");
testPostScalar($reply2, "ID", "id");
testPostScalar($reply2, "Thread", "thread");
testPostJID($reply2, "To", "user1", "server1", "resource1");
testPostScalar($reply2, "Type", "type");

is( $reply2->GetXML(), "<message from='user2\@server2/resource2' id='id' to='user1\@server1/resource1' type='type'><thread>thread</thread></message>", "GetXML()");

