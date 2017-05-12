use lib "t/lib";
use Test::More tests=>48;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $line = "-"x40;

#------------------------------------------------------------------------------
# Delete
#------------------------------------------------------------------------------
my $query1 = new Net::Jabber::Stanza("pubsub");
ok( defined($query1), "new() - delete $line" );
isa_ok( $query1, "Net::Jabber::Stanza" );
isa_ok( $query1, "Net::XMPP::Stanza" );

testScalar($query1,"XMLNS","http://jabber.org/protocol/pubsub#event");

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'/>", "GetXML()" );

my $delete1 = $query1->AddDelete();

testScalar($delete1,"Node","node1");

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'><delete node='node1'/></pubsub>", "GetXML()" );

my $delete2 = $query1->AddDelete(node=>'node2');

testPostScalar($delete2,"Node","node2");

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'><delete node='node1'/><delete node='node2'/></pubsub>", "GetXML()" );

my @deletes = $query1->GetDelete();

is( $#deletes, 1, "two deletes");

is( $deletes[0]->GetXML(), "<delete node='node1'/>", "delete[0]");
is( $deletes[1]->GetXML(), "<delete node='node2'/>", "delete[1]");


#------------------------------------------------------------------------------
# Items
#------------------------------------------------------------------------------
my $query7 = new Net::Jabber::Stanza("pubsub");
ok( defined($query7), "new() - items $line" );
isa_ok( $query7, "Net::Jabber::Stanza" );
isa_ok( $query7, "Net::XMPP::Stanza" );

testScalar($query7,"XMLNS","http://jabber.org/protocol/pubsub#event");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'/>", "GetXML()" );

my $items1 = $query7->AddItems();

testScalar($items1,"Node","node1");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'><items node='node1'/></pubsub>", "GetXML()" );

my $item1 = $items1->AddItem();

testScalar($item1,"ID","id1");
testScalar($item1,"Payload","<test/>");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'><items node='node1'><item id='id1'><test/></item></items></pubsub>", "GetXML()" );

my $item2 = $items1->AddItem(id=>"id2",
                             payload=>"<test2/>");

testPostScalar($item2,"ID","id2");
testPostScalar($item2,"Payload","<test2/>");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'><items node='node1'><item id='id1'><test/></item><item id='id2'><test2/></item></items></pubsub>", "GetXML()" );

$query7->AddItems();

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#event'><items node='node1'><item id='id1'><test/></item><item id='id2'><test2/></item></items><items/></pubsub>", "GetXML()" );

my @items = $query7->GetItems();

is( $#items, 1, "two items");

is( $items[0]->GetXML(), "<items node='node1'><item id='id1'><test/></item><item id='id2'><test2/></item></items>","items[0]");

is( $items[1]->GetXML(), "<items/>","items[1]");

my @item = $items[0]->GetItem();

is( $#item, 1, "two item");

is( $item[0]->GetXML(), "<item id='id1'><test/></item>","item[0]");
is( $item[1]->GetXML(), "<item id='id2'><test2/></item>","item[1]");

