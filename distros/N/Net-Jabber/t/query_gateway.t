use lib "t/lib";
use Test::More tests=>42;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:gateway");

testJID($query,"JID","user1","server1","resource1");
testScalar($query,"Desc","desc");
testScalar($query,"Prompt","prompt");

is( $query->GetXML(), "<query xmlns='jabber:iq:gateway'><jid>user1\@server1/resource1</jid><desc>desc</desc><prompt>prompt</prompt></query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:gateway");

$query2->SetGateway(jid=>"user2\@server2/resource2",
                    desc=>"desc",
                    prompt=>"prompt"
                    );

testPostJID($query2,"JID","user2","server2","resource2");
testPostScalar($query2,"Desc","desc");
testPostScalar($query2,"Prompt","prompt");

is( $query2->GetXML(), "<query xmlns='jabber:iq:gateway'><desc>desc</desc><jid>user2\@server2/resource2</jid><prompt>prompt</prompt></query>", "GetXML()" );

