use lib "t/lib";
use Test::More tests=>88;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

#------------------------------------------------------------------------------
# iq
#------------------------------------------------------------------------------
my $iq = new Net::Jabber::IQ();
ok( defined($iq), "new()");
isa_ok( $iq, "Net::Jabber::IQ");
isa_ok( $iq, "Net::XMPP::IQ");

testScalar($iq, "Error", "error");
testScalar($iq, "ErrorCode", "401");
testJID($iq, "From", "user1", "server1", "resource1");
testScalar($iq, "ID", "id");
testJID($iq, "To", "user2", "server2", "resource2");
testScalar($iq, "Type", "Type");

is( $iq->DefinedQuery("jabber:x:oob"), "", "not DefinedChild - jabber:x:oob" );
is( $iq->DefinedQuery("jabber:iq:roster"), "", "not DefinedChild - jabber:iq:roster" );

#------------------------------------------------------------------------------
# query - roster
#------------------------------------------------------------------------------
my $xroster = $iq->NewQuery("jabber:iq:roster");
ok( defined( $xroster ), "NewChild - jabber:iq:roster" );
isa_ok( $xroster, "Net::XMPP::Stanza" );

#------------------------------------------------------------------------------
# x - oob
#------------------------------------------------------------------------------
my $xoob = $iq->NewX("jabber:x:oob");
ok( defined( $xoob ), "NewChild - jabber:x:oob" );
isa_ok( $xoob, "Net::XMPP::Stanza" );

#------------------------------------------------------------------------------
# DefinedChild...
#------------------------------------------------------------------------------
is( $iq->DefinedQuery(), 1, "DefinedChild" );
is( $iq->DefinedQuery("jabber:iq:roster"), 1, "DefinedChild - jabber:iq:roster" );
is( $iq->DefinedX("jabber:x:oob"), 1, "DefinedChild - jabber:x:oob" );

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x2 = $iq->GetQuery();
is( $x2[0], $xroster, "Is the first the roster?");
is( $x2[1], $xoob, "Is the second the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x3 = $iq->GetX("jabber:x:oob");
is( $#x3, 0, "filter on xmlns - only one x... right?");
is( $x3[0], $xoob, "Is the first x the oob?");

#------------------------------------------------------------------------------
# X
#------------------------------------------------------------------------------
my @x4 = $iq->GetQuery("jabber:iq:roster");
is( $#x4, 0, "filter on xmlns - only one x... right?");
is( $x4[0], $xroster, "Is the first x the roster?");

is( $iq->DefinedX("jabber:x:testns"), "", "not DefinedX - jabber:x:testns" );

#------------------------------------------------------------------------------
# iq
#------------------------------------------------------------------------------
my $iq2 = new Net::Jabber::IQ();
ok( defined($iq2), "new()");
isa_ok( $iq2, "Net::Jabber::IQ");

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

testPostScalar($iq, "Error", "error");
testPostScalar($iq, "ErrorCode", "401");
testPostJID($iq, "From", "user1", "server1", "resource1");
testPostScalar($iq, "ID", "id");
testPostJID($iq, "To", "user2", "server2", "resource2");
testPostScalar($iq, "Type", "Type");


my $iq3 = new Net::Jabber::IQ();
ok( defined($iq3), "new()");
isa_ok( $iq3, "Net::Jabber::IQ");

$iq3->SetIQ(error=>"error",
            errorcode=>"401",
            from=>"user1\@server1/resource1",
            id=>"id",
            to=>"user2\@server2/resource2",
            type=>"type");

my $query = $iq3->NewQuery("jabber:iq:auth");
ok( defined($query), "new()");
isa_ok( $query, "Net::XMPP::Stanza");

$query->SetAuth(username=>"user",
                password=>"pass");

is( $iq3->GetXML(), "<iq from='user1\@server1/resource1' id='id' to='user2\@server2/resource2' type='type'><error code='401'>error</error><query xmlns='jabber:iq:auth'><password>pass</password><username>user</username></query></iq>", "GetXML()");

my $reply = $iq3->Reply();

is( $reply->GetXML(), "<iq from='user2\@server2/resource2' id='id' to='user1\@server1/resource1' type='result'><query xmlns='jabber:iq:auth'/></iq>", "GetXML()");


