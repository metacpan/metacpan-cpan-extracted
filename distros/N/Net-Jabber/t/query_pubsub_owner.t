use lib "t/lib";
use Test::More tests=>22;

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

testScalar($query1,"XMLNS","http://jabber.org/protocol/pubsub#owner");

is( $query1->GetXML(), "<pubsub xmlns='http://jabber.org/protocol/pubsub#owner'/>", "GetXML()" );

testScalar($query1,"Action","action1");

is( $query1->GetXML(), "<pubsub action='action1' xmlns='http://jabber.org/protocol/pubsub#owner'/>", "GetXML()" );

my $delete1 = $query1->AddConfigure();

testScalar($delete1,"Node","node1");

is( $query1->GetXML(), "<pubsub action='action1' xmlns='http://jabber.org/protocol/pubsub#owner'><configure node='node1'/></pubsub>", "GetXML()" );

my $delete2 = $query1->AddConfigure(node=>'node2');

testPostScalar($delete2,"Node","node2");

is( $query1->GetXML(), "<pubsub action='action1' xmlns='http://jabber.org/protocol/pubsub#owner'><configure node='node1'/><configure node='node2'/></pubsub>", "GetXML()" );

my @configure = $query1->GetConfigure();

is( $#configure, 1, "two configure");

is( $configure[0]->GetXML(), "<configure node='node1'/>", "configure[0]");
is( $configure[1]->GetXML(), "<configure node='node2'/>", "configure[1]");


