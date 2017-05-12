use lib "t/lib";
use Test::More tests=>20;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:agents");

my $agent = $query->AddAgent();
ok( defined($agent), "AddAgent()");
isa_ok($agent, "Net::Jabber::Stanza");
isa_ok($agent, "Net::XMPP::Stanza");

is( $agent->GetXMLNS(), "jabber:iq:agent", "xmlns = 'jabber:iq:agent'");

$agent->SetAgent(jid=>"user1\@server1/resource1",
                 name=>"name1");
is( $query->GetXML(), "<query xmlns='jabber:iq:agents'><agent jid='user1\@server1/resource1'><name>name1</name></agent></query>", "GetXML()" );

my $agent2 = $query->AddAgent(jid=>"user2\@server2/resource2",
                              name=>"name2");
ok( defined($agent2), "AddAgent()");
isa_ok($agent2, "Net::Jabber::Stanza");
isa_ok($agent2, "Net::XMPP::Stanza");

is( $agent2->GetXMLNS(), "jabber:iq:agent", "xmlns = 'jabber:iq:agent'");

is( $query->GetXML(), "<query xmlns='jabber:iq:agents'><agent jid='user1\@server1/resource1'><name>name1</name></agent><agent jid='user2\@server2/resource2'><name>name2</name></agent></query>", "GetXML()" );

my @agents = $query->GetAgents();
is( $#agents, 1, "two agents?");

is( $agents[0]->GetXML(), "<agent jid='user1\@server1/resource1'><name>name1</name></agent>", "agent GetXML()" );
is( $agents[1]->GetXML(), "<agent jid='user2\@server2/resource2'><name>name2</name></agent>", "agent GetXML()" );




