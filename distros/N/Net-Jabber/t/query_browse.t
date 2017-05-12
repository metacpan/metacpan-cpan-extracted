use lib "t/lib";
use Test::More tests=>167;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("item");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:browse");

testScalar($query,"Category","category");
testJID($query,"JID","user1","server1","resource1");
testScalar($query,"Name","name");
testScalar($query,"Type","type");
testScalar($query,"NS","ns");

is( $query->GetXML(), "<item category='category' jid='user1\@server1/resource1' name='name' type='type' xmlns='jabber:iq:browse'><ns>ns</ns></item>", "GetXML()" );

my $item1 = $query->AddItem();
ok( defined($item1), "new()" );
isa_ok( $item1, "Net::Jabber::Stanza" );
isa_ok( $item1, "Net::XMPP::Stanza" );

testScalar($item1,"Category","category");
testJID($item1,"JID","user2","server2","resource2");
testScalar($item1,"Name","name");
testScalar($item1,"Type","type");
testScalar($item1,"NS","ns");

is( $item1->GetXML(), "<item category='category' jid='user2\@server2/resource2' name='name' type='type'><ns>ns</ns></item>", "GetXML()" );

my $item2 = $query->AddItem(category=>"category",
                            jid=>"user3\@server3/resource3",
                            name=>"name",
                            type=>"type",
                            ns=>["ns1","ns2"]
                           );
ok( defined($item2), "new()" );
isa_ok( $item2, "Net::Jabber::Stanza" );
isa_ok( $item2, "Net::XMPP::Stanza" );

testPostScalar($item2,"Category","category");
testPostJID($item2,"JID","user3","server3","resource3");
testPostScalar($item2,"Name","name");
testPostScalar($item2,"Type","type");

is( $item2->GetXML(), "<item category='category' jid='user3\@server3/resource3' name='name' type='type'><ns>ns1</ns><ns>ns2</ns></item>", "GetXML()" );

is( $query->GetXML(), "<item category='category' jid='user1\@server1/resource1' name='name' type='type' xmlns='jabber:iq:browse'><ns>ns</ns><item category='category' jid='user2\@server2/resource2' name='name' type='type'><ns>ns</ns></item><item category='category' jid='user3\@server3/resource3' name='name' type='type'><ns>ns1</ns><ns>ns2</ns></item></item>", "GetXML()" );

my @items = $query->GetItems();
is( $#items, 1, "are there two items?" );
is( $items[0]->GetXML(), "<item category='category' jid='user2\@server2/resource2' name='name' type='type'><ns>ns</ns></item>", "GetXML()" );
is( $items[1]->GetXML(), "<item category='category' jid='user3\@server3/resource3' name='name' type='type'><ns>ns1</ns><ns>ns2</ns></item>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("item");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:browse");

$query2->SetBrowse(category=>"category",
                   jid=>"user2\@server2/resource2",
                   name=>"name",
                   type=>"type",
                   ns=>["ns1","ns2"]
                  );

testPostScalar($query2,"Category","category");
testPostJID($query2,"JID","user2","server2","resource2");
testPostScalar($query2,"Name","name");
testPostScalar($query2,"Type","type");
my @ns = $query2->GetNS();
is( $#ns, 1, "are there two ns?" );
is( $ns[0], "ns1", "ns[0] == 'ns1'" );
is( $ns[1], "ns2", "ns[1] == 'ns2'" );

is( $query2->GetXML(), "<item category='category' jid='user2\@server2/resource2' name='name' type='type' xmlns='jabber:iq:browse'><ns>ns1</ns><ns>ns2</ns></item>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("service");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","jabber:iq:browse");

testJID($query3,"JID","user3","server3","resource3");
testScalar($query3,"Name","name");
testScalar($query3,"Type","type");
testScalar($query3,"NS","ns");

is( $query3->GetXML(), "<service jid='user3\@server3/resource3' name='name' type='type' xmlns='jabber:iq:browse'><ns>ns</ns></service>", "GetXML()" );

my $item3 = $query3->AddItem("service");
ok( defined($item3), "new()" );
isa_ok( $item3, "Net::Jabber::Stanza" );
isa_ok( $item3, "Net::XMPP::Stanza" );

testJID($item3,"JID","user4","server4","resource4");
testScalar($item3,"Name","name");
testScalar($item3,"Type","type");
testScalar($item3,"NS","ns");

is( $item3->GetXML(), "<service jid='user4\@server4/resource4' name='name' type='type'><ns>ns</ns></service>", "GetXML()" );

my $item4 = $query3->AddItem("conference",
                             jid=>"user5\@server5/resource5",
                             name=>"name",
                             type=>"type"
                           );
ok( defined($item4), "new()" );
isa_ok( $item4, "Net::Jabber::Stanza" );
isa_ok( $item4, "Net::XMPP::Stanza" );

testPostJID($item4,"JID","user5","server5","resource5");
testPostScalar($item4,"Name","name");
testPostScalar($item4,"Type","type");

is( $item4->GetXML(), "<conference jid='user5\@server5/resource5' name='name' type='type'/>", "GetXML()" );

is( $query3->GetXML(), "<service jid='user3\@server3/resource3' name='name' type='type' xmlns='jabber:iq:browse'><ns>ns</ns><service jid='user4\@server4/resource4' name='name' type='type'><ns>ns</ns></service><conference jid='user5\@server5/resource5' name='name' type='type'/></service>", "GetXML()" );

@items = $query3->GetItems();
is( $#items, 1, "are there two items?" );
is( $items[0]->GetXML(), "<service jid='user4\@server4/resource4' name='name' type='type'><ns>ns</ns></service>", "GetXML()" );
is( $items[1]->GetXML(), "<conference jid='user5\@server5/resource5' name='name' type='type'/>", "GetXML()" );

