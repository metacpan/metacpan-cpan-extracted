use lib "t/lib";
use Test::More tests=>70;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","http://jabber.org/protocol/disco#items");

testScalar($query,"Node","node");

is( $query->GetXML(), "<query node='node' xmlns='http://jabber.org/protocol/disco#items'/>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","http://jabber.org/protocol/disco#items");

$query2->SetDiscoItems(node=>'node');

testPostScalar($query2,"Node","node");

is( $query2->GetXML(), "<query node='node' xmlns='http://jabber.org/protocol/disco#items'/>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("query");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","http://jabber.org/protocol/disco#items");

testScalar($query3,"Node","node");

my $item = $query3->AddItem();
isa_ok( $item, "Net::Jabber::Stanza" );
isa_ok( $item, "Net::XMPP::Stanza" );

testScalar($item,"Action","action");
testJID($item,"JID","user1","server1","resource1");
testScalar($item,"Name","name");
testScalar($item,"Node","node");


is( $query3->GetXML(), "<query node='node' xmlns='http://jabber.org/protocol/disco#items'><item action='action' jid='user1\@server1/resource1' name='name' node='node'/></query>", "GetXML()" );

my $item2 = $query3->AddItem(action=>"action",
                             jid=>'user2@server2/resource2',
                             name=>"name",
                             node=>"node"
                            );
isa_ok( $item2, "Net::Jabber::Stanza" );
isa_ok( $item2, "Net::XMPP::Stanza" );

testPostScalar($item2,"Action","action");
testPostJID($item2,"JID","user2","server2","resource2");
testPostScalar($item2,"Name","name");
testPostScalar($item2,"Node","node");


is( $query3->GetXML(), "<query node='node' xmlns='http://jabber.org/protocol/disco#items'><item action='action' jid='user1\@server1/resource1' name='name' node='node'/><item action='action' jid='user2\@server2/resource2' name='name' node='node'/></query>", "GetXML()" );

my @items = $query3->GetItems();
is($#items,1,"two items");

is( $items[0]->GetXML(), "<item action='action' jid='user1\@server1/resource1' name='name' node='node'/>","item 1 - GetXML()");
is( $items[1]->GetXML(), "<item action='action' jid='user2\@server2/resource2' name='name' node='node'/>","item 2 - GetXML()");

