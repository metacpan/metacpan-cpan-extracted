use lib "t/lib";
use Test::More tests=>455;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $line = "-"x40;

#------------------------------------------------------------------------------
# Affiliations
#------------------------------------------------------------------------------
my $query1 = new Net::Jabber::Stanza("pubsub");
ok( defined($query1), "new() - affiliations $line" );
isa_ok( $query1, "Net::Jabber::Stanza" );
isa_ok( $query1, "Net::XMPP::Stanza" );

testScalar($query1,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $affiliations = $query1->AddAffiliations();

my $aff_entity1 = $affiliations->AddEntity();

testScalar($aff_entity1,"Affiliation","affiliation1");
testJID($aff_entity1,"JID","user1","server1","resource1");
testScalar($aff_entity1,"Node","node1");
testScalar($aff_entity1,"Subscription","subscription1");

my $aff_entity1_subopt = $aff_entity1->AddSubscribeOptions();

testFlag($aff_entity1_subopt,"Required");

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><affiliations><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity></affiliations></pubsub>", "GetXML()" );

my $aff_entity2 = $affiliations->AddEntity(affiliation=>'affiliation2',
                                           jid=>'user2@server2/resource2',
                                           node=>'node2',
                                           subscription=>'subscription2'
                                          );

my $aff_entity2_subopt = $aff_entity2->AddSubscribeOptions(required=>1);

testPostScalar($aff_entity2,"Affiliation","affiliation2");
testPostJID($aff_entity2,"JID","user2","server2","resource2");
testPostScalar($aff_entity2,"Node","node2");
testPostScalar($aff_entity2,"Subscription","subscription2");

testPostFlag($aff_entity2_subopt,"Required");

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><affiliations><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'><subscribe-options><required/></subscribe-options></entity></affiliations></pubsub>", "GetXML()" );

$query1->AddAffiliations();

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><affiliations><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'><subscribe-options><required/></subscribe-options></entity></affiliations><affiliations/></pubsub>", "GetXML()" );

my @affiliations = $query1->GetAffiliations();

is( $#affiliations, 1, "two affiliations");

is( $affiliations[0]->GetXML(), "<affiliations><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'><subscribe-options><required/></subscribe-options></entity></affiliations>","affiliations[0]");

is( $affiliations[1]->GetXML(), "<affiliations/>","affiliations[1]");

my @aff_entities = $affiliations[0]->GetEntity();

is( $#aff_entities, 1, "two entities");

is( $aff_entities[0]->GetXML(), "<entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity>","aff_entities[0]");
ok( $aff_entities[0]->GetSubscribeOptions()->GetRequired(), "aff_entities[0] - subopts required");
is( $aff_entities[1]->GetXML(), "<entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'><subscribe-options><required/></subscribe-options></entity>","aff_entities[1]");
ok( $aff_entities[1]->GetSubscribeOptions()->GetRequired(), "aff_entities[1] - subopts required");

$query1->RemoveAffiliations();

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Configure
#------------------------------------------------------------------------------
my $query2 = new Net::Jabber::Stanza("pubsub");
ok( defined($query2), "new() - configure $line" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query2->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $configure1 = $query2->AddConfigure();

testScalar($configure1,"Node","node1");

is( $query2->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><configure node='node1'/></pubsub>", "GetXML()" );

my $configure2 = $query2->AddConfigure(node=>'node2');

testPostScalar($configure2,"Node","node2");

is( $query2->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><configure node='node1'/><configure node='node2'/></pubsub>", "GetXML()" );

my @configures = $query2->GetConfigure();

is( $#configures, 1, "two configures");

is( $configures[0]->GetXML(), "<configure node='node1'/>", "configure[0]");
is( $configures[1]->GetXML(), "<configure node='node2'/>", "configure[1]");

$query2->RemoveConfigure();

is( $query2->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Create
#------------------------------------------------------------------------------
my $query3 = new Net::Jabber::Stanza("pubsub");
ok( defined($query3), "new() - create $line" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query3->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $create1 = $query3->AddCreate();

is( $query3->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><create/></pubsub>", "GetXML()" );

testScalar($create1,"Node","node1");

is( $query3->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><create node='node1'/></pubsub>", "GetXML()" );

my $create2 = $query3->AddCreate(node=>'node2');

testPostScalar($create2,"Node","node2");

is( $query3->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><create node='node1'/><create node='node2'/></pubsub>", "GetXML()" );

my @creates = $query3->GetCreate();

is( $#creates, 1, "two creates");

is( $creates[0]->GetXML(), "<create node='node1'/>", "create[0]");
is( $creates[1]->GetXML(), "<create node='node2'/>", "create[1]");

$query3->RemoveCreate();

is( $query3->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Delete
#------------------------------------------------------------------------------
my $query4 = new Net::Jabber::Stanza("pubsub");
ok( defined($query4), "new() - delete $line" );
isa_ok( $query4, "Net::Jabber::Stanza" );
isa_ok( $query4, "Net::XMPP::Stanza" );

testScalar($query4,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query4->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $delete1 = $query4->AddDelete();

testScalar($delete1,"Node","node1");

is( $query4->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><delete node='node1'/></pubsub>", "GetXML()" );

my $delete2 = $query4->AddDelete(node=>'node2');

testPostScalar($delete2,"Node","node2");

is( $query4->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><delete node='node1'/><delete node='node2'/></pubsub>", "GetXML()" );

my @deletes = $query4->GetDelete();

is( $#deletes, 1, "two deletes");

is( $deletes[0]->GetXML(), "<delete node='node1'/>", "delete[0]");
is( $deletes[1]->GetXML(), "<delete node='node2'/>", "delete[1]");

$query4->RemoveDelete();

is( $query4->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Entities
#------------------------------------------------------------------------------
my $query5 = new Net::Jabber::Stanza("pubsub");
ok( defined($query5), "new() - entities $line" );
isa_ok( $query5, "Net::Jabber::Stanza" );
isa_ok( $query5, "Net::XMPP::Stanza" );

testScalar($query5,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query5->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $entities1 = $query5->AddEntities();

is( $query5->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entities/></pubsub>", "GetXML()" );

my $ents_entity1 = $entities1->AddEntity();

testScalar($ents_entity1,"Affiliation","affiliation1");
testJID($ents_entity1,"JID","user1","server1","resource1");
testScalar($ents_entity1,"Node","node1");
testScalar($ents_entity1,"Subscription","subscription1");

is( $query5->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entities><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'/></entities></pubsub>", "GetXML()" );

my $ents_entity2 = $entities1->AddEntity(affiliation=>"affiliation2",
                                    jid=>'user2@server2/resource2',
                                    node=>"node2",
                                    subscription=>"subscription2");

testPostScalar($ents_entity2,"Affiliation","affiliation2");
testPostJID($ents_entity2,"JID","user2","server2","resource2");
testPostScalar($ents_entity2,"Node","node2");
testPostScalar($ents_entity2,"Subscription","subscription2");

is( $query5->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entities><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'/><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'/></entities></pubsub>", "GetXML()" );

$query5->AddEntities();

is( $query5->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entities><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'/><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'/></entities><entities/></pubsub>", "GetXML()" );

my @ents_entities = $query5->GetEntities();

is( $#ents_entities, 1, "two entities");

is( $ents_entities[0]->GetXML(), "<entities><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'/><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'/></entities>","ents_entities[0]");

is( $ents_entities[1]->GetXML(), "<entities/>","ents_entities[1]");

my @ents_entity = $ents_entities[0]->GetEntity();

is( $#ents_entity, 1, "two entities");

is( $ents_entity[0]->GetXML(), "<entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'/>","ents_entities[0]");
is( $ents_entity[1]->GetXML(), "<entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'/>","ents_entities[1]");

$query5->RemoveEntities();

is( $query5->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Entity
#------------------------------------------------------------------------------
my $query6 = new Net::Jabber::Stanza("pubsub");
ok( defined($query6), "new() - entity $line" );
isa_ok( $query6, "Net::Jabber::Stanza" );
isa_ok( $query6, "Net::XMPP::Stanza" );

testScalar($query6,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query6->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $entity1 = $query6->AddEntity();

testScalar($entity1,"Affiliation","affiliation1");
testJID($entity1,"JID","user1","server1","resource1");
testScalar($entity1,"Node","node1");
testScalar($entity1,"Subscription","subscription1");

is( $query6->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'/></pubsub>", "GetXML()" );

my $subopts1 = $entity1->AddSubscribeOptions();

testFlag($subopts1,"Required");

is( $query6->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity></pubsub>", "GetXML()" );

my $entity2 = $query6->AddEntity(affiliation=>"affiliation2",
                                 jid=>'user2@server2/resource2',
                                 node=>"node2",
                                 subscription=>"subscription2");

testPostScalar($entity2,"Affiliation","affiliation2");
testPostJID($entity2,"JID","user2","server2","resource2");
testPostScalar($entity2,"Node","node2");
testPostScalar($entity2,"Subscription","subscription2");

is( $query6->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'/></pubsub>", "GetXML()" );

my $subopts2 = $entity2->AddSubscribeOptions(required=>1);

testPostFlag($subopts2,"Required");

is( $query6->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity><entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'><subscribe-options><required/></subscribe-options></entity></pubsub>", "GetXML()" );

my @entities = $query6->GetEntity();

is( $#entities, 1, "two entities");

is( $entities[0]->GetXML(), "<entity affiliation='affiliation1' jid='user1\@server1/resource1' node='node1' subscription='subscription1'><subscribe-options><required/></subscribe-options></entity>","entities[0]");
ok( $entities[0]->GetSubscribeOptions()->GetRequired(), "entities[0] - subopts required");
is( $entities[1]->GetXML(), "<entity affiliation='affiliation2' jid='user2\@server2/resource2' node='node2' subscription='subscription2'><subscribe-options><required/></subscribe-options></entity>","entities[1]");
ok( $entities[1]->GetSubscribeOptions()->GetRequired(), "entities[1] - subopts required");

$query6->RemoveEntity();

is( $query6->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Items
#------------------------------------------------------------------------------
my $query7 = new Net::Jabber::Stanza("pubsub");
ok( defined($query7), "new() - items $line" );
isa_ok( $query7, "Net::Jabber::Stanza" );
isa_ok( $query7, "Net::XMPP::Stanza" );

testScalar($query7,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $items1 = $query7->AddItems();

testScalar($items1,"Node","node1");
testScalar($items1,"MaxItems","max1");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><items max_items='max1' node='node1'/></pubsub>", "GetXML()" );

my $its_item1 = $items1->AddItem();

testScalar($its_item1,"ID","id1");
testScalar($its_item1,"Payload","<test><foo/>bar</test>");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><items max_items='max1' node='node1'><item id='id1'><test><foo/>bar</test></item></items></pubsub>", "GetXML()" );

my $its_item2 = $items1->AddItem(id=>"id2",
                             payload=>"<bing>boo<foo/>bob</bing>");

testPostScalar($its_item2,"ID","id2");
testPostScalar($its_item2,"Payload","<bing>boo<foo/>bob</bing>");

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><items max_items='max1' node='node1'><item id='id1'><test><foo/>bar</test></item><item id='id2'><bing>boo<foo/>bob</bing></item></items></pubsub>", "GetXML()" );

$query7->AddItems();

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><items max_items='max1' node='node1'><item id='id1'><test><foo/>bar</test></item><item id='id2'><bing>boo<foo/>bob</bing></item></items><items/></pubsub>", "GetXML()" );

my @its_items = $query7->GetItems();

is( $#its_items, 1, "two items");

is( $its_items[0]->GetXML(), "<items max_items='max1' node='node1'><item id='id1'><test><foo/>bar</test></item><item id='id2'><bing>boo<foo/>bob</bing></item></items>","its_items[0]");

is( $its_items[1]->GetXML(), "<items/>","its_items[1]");

my @its_item = $its_items[0]->GetItem();

is( $#its_item, 1, "two item");

is( $its_item[0]->GetXML(), "<item id='id1'><test><foo/>bar</test></item>","its_item[0]");
is( $its_item[1]->GetXML(), "<item id='id2'><bing>boo<foo/>bob</bing></item>","its_item[1]");

$query7->RemoveItems();

is( $query7->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Item
#------------------------------------------------------------------------------
my $query8 = new Net::Jabber::Stanza("pubsub");
ok( defined($query8), "new() - item $line" );
isa_ok( $query8, "Net::Jabber::Stanza" );
isa_ok( $query8, "Net::XMPP::Stanza" );

testScalar($query8,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query8->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $item1 = $query8->AddItem();

testScalar($item1,"ID","id1");
testScalar($item1,"Payload","<test/>");

is( $query8->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><item id='id1'><test/></item></pubsub>", "GetXML()" );

my $item2 = $query8->AddItem(id=>"id2",
                             payload=>"<test2/>");

testPostScalar($item2,"ID","id2");
testPostScalar($item2,"Payload","<test2/>");


is( $query8->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><item id='id1'><test/></item><item id='id2'><test2/></item></pubsub>", "GetXML()" );

my @item = $query8->GetItem();

is( $#item, 1, "two item");

is( $item[0]->GetXML(), "<item id='id1'><test/></item>","item[0]");
is( $item[1]->GetXML(), "<item id='id2'><test2/></item>","item[1]");

$query8->RemoveItem();

is( $query8->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Options
#------------------------------------------------------------------------------
my $query9 = new Net::Jabber::Stanza("pubsub");
ok( defined($query9), "new() - options $line" );
isa_ok( $query9, "Net::Jabber::Stanza" );
isa_ok( $query9, "Net::XMPP::Stanza" );

testScalar($query9,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query9->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $options1 = $query9->AddOptions();

testJID($options1,"JID","user1","server1","resource1");
testScalar($options1,"Node","node1");

is( $query9->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><options jid='user1\@server1/resource1' node='node1'/></pubsub>", "GetXML()" );

my $options2 = $query9->AddOptions(jid=>'user2@server2/resource2',
                                   node=>"node2"
                                  );

testPostJID($options2,"JID","user2","server2","resource2");
testPostScalar($options2,"Node","node2");

is( $query9->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><options jid='user1\@server1/resource1' node='node1'/><options jid='user2\@server2/resource2' node='node2'/></pubsub>", "GetXML()" );

my @options = $query9->GetOptions();

is( $#options, 1, "two options");

is( $options[0]->GetXML(), "<options jid='user1\@server1/resource1' node='node1'/>","options[0]");
is( $options[1]->GetXML(), "<options jid='user2\@server2/resource2' node='node2'/>","options[1]");

$query9->RemoveOptions();

is( $query9->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Publish
#------------------------------------------------------------------------------
my $query10 = new Net::Jabber::Stanza("pubsub");
ok( defined($query10), "new() - publish $line" );
isa_ok( $query10, "Net::Jabber::Stanza" );
isa_ok( $query10, "Net::XMPP::Stanza" );

testScalar($query10,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query10->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $publish1 = $query10->AddPublish();

testScalar($publish1,"Node","node1");

is( $query10->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><publish node='node1'/></pubsub>", "GetXML()" );

my $pub_item1 = $publish1->AddItem();

testScalar($pub_item1,"ID","id1");
testScalar($pub_item1,"Payload","<test><foo/>bar</test>");

is( $query10->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><publish node='node1'><item id='id1'><test><foo/>bar</test></item></publish></pubsub>", "GetXML()" );

my $pub_item2 = $publish1->AddItem(id=>"id2",
                               payload=>"<bing>boo<foo/>bob</bing>");

testPostScalar($pub_item2,"ID","id2");
testPostScalar($pub_item2,"Payload","<bing>boo<foo/>bob</bing>");

is( $query10->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><publish node='node1'><item id='id1'><test><foo/>bar</test></item><item id='id2'><bing>boo<foo/>bob</bing></item></publish></pubsub>", "GetXML()" );

$query10->AddPublish();

is( $query10->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><publish node='node1'><item id='id1'><test><foo/>bar</test></item><item id='id2'><bing>boo<foo/>bob</bing></item></publish><publish/></pubsub>", "GetXML()" );

my @publish = $query10->GetPublish();

is( $#publish, 1, "two publish");

is( $publish[0]->GetXML(), "<publish node='node1'><item id='id1'><test><foo/>bar</test></item><item id='id2'><bing>boo<foo/>bob</bing></item></publish>","publish[0]");

is( $publish[1]->GetXML(), "<publish/>","publish[1]");

my @pub_item = $publish[0]->GetItem();

is( $#pub_item, 1, "two item");

is( $pub_item[0]->GetXML(), "<item id='id1'><test><foo/>bar</test></item>","pub_item[0]");
is( $pub_item[1]->GetXML(), "<item id='id2'><bing>boo<foo/>bob</bing></item>","pub_item[1]");

$query10->RemovePublish();

is( $query10->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Purge
#------------------------------------------------------------------------------
my $query11 = new Net::Jabber::Stanza("pubsub");
ok( defined($query11), "new() - purge $line" );
isa_ok( $query11, "Net::Jabber::Stanza" );
isa_ok( $query11, "Net::XMPP::Stanza" );

testScalar($query11,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query11->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $purge1 = $query11->AddPurge();

testScalar($purge1,"Node","node1");

is( $query11->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><purge node='node1'/></pubsub>", "GetXML()" );

my $purge2 = $query11->AddPurge(node=>'node2');

testPostScalar($purge2,"Node","node2");

is( $query11->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><purge node='node1'/><purge node='node2'/></pubsub>", "GetXML()" );

my @purge = $query11->GetPurge();

is( $#purge, 1, "two purge");

is( $purge[0]->GetXML(), "<purge node='node1'/>","purge[0]");
is( $purge[1]->GetXML(), "<purge node='node2'/>","purge[1]");

$query11->RemovePurge();

is( $query11->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Retract
#------------------------------------------------------------------------------
my $query12 = new Net::Jabber::Stanza("pubsub");
ok( defined($query12), "new() - retract $line" );
isa_ok( $query12, "Net::Jabber::Stanza" );
isa_ok( $query12, "Net::XMPP::Stanza" );

testScalar($query12,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query12->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $retract1 = $query12->AddRetract();

testScalar($retract1,"Node","node1");

is( $query12->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><retract node='node1'/></pubsub>", "GetXML()" );

my $ret_item1 = $retract1->AddItem();

testScalar($ret_item1,"ID","id1");

is( $query12->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><retract node='node1'><item id='id1'/></retract></pubsub>", "GetXML()" );

my $ret_item2 = $retract1->AddItem(id=>"id2");

testPostScalar($ret_item2,"ID","id2");

is( $query12->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><retract node='node1'><item id='id1'/><item id='id2'/></retract></pubsub>", "GetXML()" );

$query12->AddRetract();

is( $query12->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><retract node='node1'><item id='id1'/><item id='id2'/></retract><retract/></pubsub>", "GetXML()" );

my @retract = $query12->GetRetract();

is( $#retract, 1, "two retract");

is( $retract[0]->GetXML(), "<retract node='node1'><item id='id1'/><item id='id2'/></retract>","retract[0]");

is( $retract[1]->GetXML(), "<retract/>","retract[1]");

my @ret_item = $retract[0]->GetItem();

is( $#ret_item, 1, "two items");

is( $ret_item[0]->GetXML(), "<item id='id1'/>","ret_item[0]");
is( $ret_item[1]->GetXML(), "<item id='id2'/>","ret_item[1]");

$query12->RemoveRetract();

is( $query12->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Subscribe
#------------------------------------------------------------------------------
my $query13 = new Net::Jabber::Stanza("pubsub");
ok( defined($query13), "new() - subscribe $line" );
isa_ok( $query13, "Net::Jabber::Stanza" );
isa_ok( $query13, "Net::XMPP::Stanza" );

testScalar($query13,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query13->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $subscribe1 = $query13->AddSubscribe();

testJID($subscribe1,"JID","user1","server1","resource1");
testScalar($subscribe1,"Node","node1");

is( $query13->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><subscribe jid='user1\@server1/resource1' node='node1'/></pubsub>", "GetXML()" );

my $subscribe2 = $query13->AddSubscribe(jid=>'user2@server2/resource2',
                                        node=>"node2"
                                       );

testPostJID($subscribe2,"JID","user2","server2","resource2");
testPostScalar($subscribe2,"Node","node2");

is( $query13->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><subscribe jid='user1\@server1/resource1' node='node1'/><subscribe jid='user2\@server2/resource2' node='node2'/></pubsub>", "GetXML()" );

my @subscribe = $query13->GetSubscribe();

is( $#subscribe, 1, "two subscribe");

is( $subscribe[0]->GetXML(), "<subscribe jid='user1\@server1/resource1' node='node1'/>","subscribe[0]");
is( $subscribe[1]->GetXML(), "<subscribe jid='user2\@server2/resource2' node='node2'/>","subscribe[1]");

$query13->RemoveSubscribe();

is( $query13->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


#------------------------------------------------------------------------------
# Unsubscribe
#------------------------------------------------------------------------------
my $query14 = new Net::Jabber::Stanza("pubsub");
ok( defined($query14), "new() - unsubscribe $line" );
isa_ok( $query14, "Net::Jabber::Stanza" );
isa_ok( $query14, "Net::XMPP::Stanza" );

testScalar($query14,"XMLNS","http://jabber.org/protocol/pubsub");

is( $query14->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );

my $unsubscribe1 = $query14->AddUnsubscribe();

testJID($unsubscribe1,"JID","user1","server1","resource1");
testScalar($unsubscribe1,"Node","node1");

is( $query14->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><unsubscribe jid='user1\@server1/resource1' node='node1'/></pubsub>", "GetXML()" );

my $unsubscribe2 = $query14->AddUnsubscribe(jid=>'user2@server2/resource2',
                                            node=>"node2"
                                           );
  
testPostJID($unsubscribe2,"JID","user2","server2","resource2");
testPostScalar($unsubscribe2,"Node","node2");

is( $query14->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'><unsubscribe jid='user1\@server1/resource1' node='node1'/><unsubscribe jid='user2\@server2/resource2' node='node2'/></pubsub>", "GetXML()" );

my @unsubscribe = $query14->GetUnsubscribe();

is( $#unsubscribe, 1, "two unsubscribe");

is( $unsubscribe[0]->GetXML(), "<unsubscribe jid='user1\@server1/resource1' node='node1'/>","unsubscribe[0]");
is( $unsubscribe[1]->GetXML(), "<unsubscribe jid='user2\@server2/resource2' node='node2'/>","unsubscribe[1]");

$query14->RemoveUnsubscribe();

is( $query14->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub'/>", "GetXML()" );


