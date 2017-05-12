use lib "t/lib";
use Test::More tests=>89;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","http://jabber.org/protocol/bytestreams");

testScalar($query,"Activate","activate");
testScalar($query,"SID","sid");
testJID($query,"StreamHostUsedJID","user1","server1","resource1");

is( $query->GetXML(), "<query sid='sid' xmlns='http://jabber.org/protocol/bytestreams'><activate>activate</activate><streamhost-used jid='user1\@server1/resource1'/></query>", "GetXML()" );

my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","http://jabber.org/protocol/bytestreams");

$query2->SetByteStreams(activate=>'activate',
                        sid=>'sid',
                        streamhostusedjid=>'user2@server2/resource2'
                       );

testPostScalar($query2,"Activate","activate");
testPostScalar($query2,"SID","sid");
testPostJID($query2,"StreamHostUsedJID","user2","server2","resource2");

is( $query2->GetXML(), "<query sid='sid' xmlns='http://jabber.org/protocol/bytestreams'><activate>activate</activate><streamhost-used jid='user2\@server2/resource2'/></query>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("query");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","http://jabber.org/protocol/bytestreams");

my $host = $query3->AddStreamHost();
isa_ok( $host, "Net::Jabber::Stanza" );
isa_ok( $host, "Net::XMPP::Stanza" );

testScalar($host,"Host","host1");
testJID($host,"JID","user3","server3","resource3");
testScalar($host,"Port","port1");
testScalar($host,"ZeroConf","zeroconf1");


is( $query3->GetXML(), "<query xmlns='http://jabber.org/protocol/bytestreams'><streamhost host='host1' jid='user3\@server3/resource3' port='port1' zeroconf='zeroconf1'/></query>", "GetXML()" );

my $host2 = $query3->AddStreamHost(host=>"host2",
                                   jid=>'user4@server4/resource4',
                                   port=>"port2",
                                   zeroconf=>"zeroconf2"
                                  );
isa_ok( $host2, "Net::Jabber::Stanza" );
isa_ok( $host2, "Net::XMPP::Stanza" );

testPostScalar($host2,"Host","host2");
testPostJID($host2,"JID","user4","server4","resource4");
testPostScalar($host2,"Port","port2");
testPostScalar($host2,"ZeroConf","zeroconf2");


is( $query3->GetXML(), "<query xmlns='http://jabber.org/protocol/bytestreams'><streamhost host='host1' jid='user3\@server3/resource3' port='port1' zeroconf='zeroconf1'/><streamhost host='host2' jid='user4\@server4/resource4' port='port2' zeroconf='zeroconf2'/></query>", "GetXML()" );

my @hosts = $query3->GetStreamHosts();
is($#hosts,1,"two items");

is( $hosts[0]->GetXML(), "<streamhost host='host1' jid='user3\@server3/resource3' port='port1' zeroconf='zeroconf1'/>","item 1 - GetXML()");
is( $hosts[1]->GetXML(), "<streamhost host='host2' jid='user4\@server4/resource4' port='port2' zeroconf='zeroconf2'/>","item 2 - GetXML()");


