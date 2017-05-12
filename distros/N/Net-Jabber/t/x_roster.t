use lib "t/lib";
use Test::More tests=>66;

BEGIN{ use_ok( "Net::Jabber" ); }

my $debug = new Net::XMPP::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

require "t/mytestlib.pl";

my $x = new Net::Jabber::Stanza("x");
ok( defined($x), "new()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($x,"XMLNS","jabber:x:roster");

my $item1 = $x->AddItem();
ok( defined($x), "AddItem()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($item1, "Group", "group");
testJID($item1, "JID", "user1", "server1", "resource1");
testScalar($item1, "Name", "name");

is( $x->GetXML(), "<x xmlns='jabber:x:roster'><item jid='user1\@server1/resource1' name='name'><group>group</group></item></x>", "GetXML()" );

my $item2 = $x->AddItem(group=>["group1","group2"],
                        jid=>"user2\@server2/resource2",
                        name=>"user2");


ok( $item2->DefinedGroup(), "group defined");

my @groups = $item2->GetGroup();
is_deeply(\@groups, ["group1","group2"], "groups match");
testPostJID($item2, "JID", "user2", "server2", "resource2");
testPostScalar($item2, "Name", "user2");

is( $x->GetXML(), "<x xmlns='jabber:x:roster'><item jid='user1\@server1/resource1' name='name'><group>group</group></item><item jid='user2\@server2/resource2' name='user2'><group>group1</group><group>group2</group></item></x>", "GetXML()" );

my @items = $x->GetItems();
is( $#items, 1, "two items");

testPostScalar($items[0], "Group", "group");
testPostJID($items[0], "JID", "user1", "server1", "resource1");
testPostScalar($items[0], "Name", "name");

is( $items[0]->GetXML(), "<item jid='user1\@server1/resource1' name='name'><group>group</group></item>", "GetXML()");

my @groups2 = $items[1]->GetGroup();
is_deeply(\@groups2, ["group1","group2"], "groups match");
testPostJID($items[1], "JID", "user2", "server2", "resource2");
testPostScalar($items[1], "Name", "user2");

is( $items[1]->GetXML(), "<item jid='user2\@server2/resource2' name='user2'><group>group1</group><group>group2</group></item>", "GetXML()");


$x->RemoveItems();

is( $x->GetXML(), "<x xmlns='jabber:x:roster'/>", "GetXML()" );

