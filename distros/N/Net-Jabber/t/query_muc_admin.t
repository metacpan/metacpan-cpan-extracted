use lib "t/lib";
use Test::More tests=>72;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS",'http://jabber.org/protocol/muc#admin');

my $item1 = $query->AddItem();
ok( defined($item1), "new()" );
isa_ok( $item1, "Net::Jabber::Stanza" );
isa_ok( $item1, "Net::XMPP::Stanza" );

testJID($item1,"ActorJID","user1", "server1", "resource1");
testScalar($item1,"Affiliation","affiliation");
testJID($item1,"JID","user2", "server2", "resource2");
testScalar($item1,"Nick","nick");
testScalar($item1,"Reason","reason");
testScalar($item1,"Role","role");

is( $query->GetXML(), "<query xmlns='http://jabber.org/protocol/muc#admin'><item affiliation='affiliation' jid='user2\@server2/resource2' nick='nick' role='role'><actor jid='user1\@server1/resource1'/><reason>reason</reason></item></query>", "GetXML()");

my $item2 = $query->AddItem(actorjid=>'user3@server3/resource3',
                            affiliation=>"affiliation",
                            jid=>'user4@server4/resource4',
                            nick=>"nick",
                            reason=>"reason",
                            role=>"role");
ok( defined($item2), "new()" );
isa_ok( $item2, "Net::Jabber::Stanza" );
isa_ok( $item2, "Net::XMPP::Stanza" );

testPostJID($item2,"ActorJID","user3", "server3", "resource3");
testPostScalar($item2,"Affiliation","affiliation");
testPostJID($item2,"JID","user4", "server4", "resource4");
testPostScalar($item2,"Nick","nick");
testPostScalar($item2,"Reason","reason");
testPostScalar($item2,"Role","role");

is( $query->GetXML(), "<query xmlns='http://jabber.org/protocol/muc#admin'><item affiliation='affiliation' jid='user2\@server2/resource2' nick='nick' role='role'><actor jid='user1\@server1/resource1'/><reason>reason</reason></item><item affiliation='affiliation' jid='user4\@server4/resource4' nick='nick' role='role'><actor jid='user3\@server3/resource3'/><reason>reason</reason></item></query>", "GetXML()");

my @items = $query->GetItems();
is( $#items, 1, "are there two items?" );
is( $items[0]->GetXML(), "<item affiliation='affiliation' jid='user2\@server2/resource2' nick='nick' role='role'><actor jid='user1\@server1/resource1'/><reason>reason</reason></item>", "GetXML()" );
is( $items[1]->GetXML(), "<item affiliation='affiliation' jid='user4\@server4/resource4' nick='nick' role='role'><actor jid='user3\@server3/resource3'/><reason>reason</reason></item>", "GetXML()" );

