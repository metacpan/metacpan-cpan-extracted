use lib "t/lib";
use Test::More tests=>57;

BEGIN{ use_ok( "Net::XMPP3" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP3::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

my $query = new Net::XMPP3::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::XMPP3::Stanza" );

testScalar($query,"XMLNS","jabber:iq:roster");

my $item1 = $query->AddItem();
ok( defined($item1), "new()" );
isa_ok( $item1, "Net::XMPP3::Stanza" );

testScalar($item1,"Ask","ask");
testScalar($item1,"Group","groupA");

my @groups = $item1->GetGroup();
is( $#groups, 0, "is there one group?" );
is( $groups[0], "groupA", "groupA" );

testJID($item1,"JID","user1","server1","resource1");
testScalar($item1,"Name","name");
testScalar($item1,"Subscription","from");

is( $query->GetXML(), "<query xmlns='jabber:iq:roster'><item ask='ask' jid='user1\@server1/resource1' name='name' subscription='from'><group>groupA</group></item></query>", "GetXML()" );


my $item2 = $query->AddItem(ask=>"ask",
                            group=>["group1","group2"],
                            jid=>"user2\@server2/resource2",
                            name=>"name2",
                            subscription=>"both"
                           ); 
ok( defined($item2), "new()" );
isa_ok( $item2, "Net::XMPP3::Stanza" );

testPostScalar($item2,"Ask","ask");

@groups = $item2->GetGroup();
is( $#groups, 1, "are there two groups?" );
is( $groups[0], "group1", "group1" );
is( $groups[1], "group2", "group2" );

testPostJID($item2,"JID","user2","server2","resource2");
testPostScalar($item2,"Name","name2");
testPostScalar($item2,"Subscription","both");

is( $query->GetXML(), "<query xmlns='jabber:iq:roster'><item ask='ask' jid='user1\@server1/resource1' name='name' subscription='from'><group>groupA</group></item><item ask='ask' jid='user2\@server2/resource2' name='name2' subscription='both'><group>group1</group><group>group2</group></item></query>", "GetXML()" );

my $item3 = $query->AddItem(ask=>"ask",
                            jid=>"user3\@server3/resource3",
                            subscription=>"both"
                           );
ok( defined($item3), "new()" );
isa_ok( $item3, "Net::XMPP3::Stanza" );

is( $query->GetXML(), "<query xmlns='jabber:iq:roster'><item ask='ask' jid='user1\@server1/resource1' name='name' subscription='from'><group>groupA</group></item><item ask='ask' jid='user2\@server2/resource2' name='name2' subscription='both'><group>group1</group><group>group2</group></item><item ask='ask' jid='user3\@server3/resource3' subscription='both'/></query>", "GetXML()" ); 

my @items = $query->GetItems();
is( $#items, 2, "are there three items?" );
is( $items[0]->GetXML(), "<item ask='ask' jid='user1\@server1/resource1' name='name' subscription='from'><group>groupA</group></item>", "GetXML()" );
is( $items[1]->GetXML(), "<item ask='ask' jid='user2\@server2/resource2' name='name2' subscription='both'><group>group1</group><group>group2</group></item>", "GetXML()" );
is( $items[2]->GetXML(), "<item ask='ask' jid='user3\@server3/resource3' subscription='both'/>", "GetXML()" );



