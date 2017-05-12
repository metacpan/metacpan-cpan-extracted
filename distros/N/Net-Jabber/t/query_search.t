use lib "t/lib";
use Test::More tests=>140;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:search");

testScalar($query,"Email","email");
testScalar($query,"Family","family");
testScalar($query,"First","first");
testScalar($query,"Given","given");
testScalar($query,"Instructions","instructions");
testScalar($query,"Key","key");
testScalar($query,"Last","last");
testScalar($query,"Name","name");
testScalar($query,"Nick","nick");
testFlag($query,"Truncated");

is( $query->GetXML(), "<query xmlns='jabber:iq:search'><email>email</email><family>family</family><first>first</first><given>given</given><instructions>instructions</instructions><key>key</key><last>last</last><name>name</name><nick>nick</nick><truncated/></query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:search");

$query2->SetSearch(email=>"email",
                   family=>"family",
                   first=>"first",
                   given=>"given",
                   instructions=>"instructions",
                   key=>"key",
                   last=>"last",
                   name=>"name",
                   nick=>"nick",
                   truncated=>1,
                  );

testPostScalar($query2,"Email","email");
testPostScalar($query2,"Family","family");
testPostScalar($query2,"First","first");
testPostScalar($query2,"Given","given");
testPostScalar($query2,"Instructions","instructions");
testPostScalar($query2,"Key","key");
testPostScalar($query2,"Last","last");
testPostScalar($query2,"Name","name");
testPostScalar($query2,"Nick","nick");
testPostFlag($query2,"Truncated");

is( $query2->GetXML(), "<query xmlns='jabber:iq:search'><email>email</email><family>family</family><first>first</first><given>given</given><instructions>instructions</instructions><key>key</key><last>last</last><name>name</name><nick>nick</nick><truncated/></query>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("query");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","jabber:iq:search");

my $item1 = $query3->AddItem();
ok( defined($item1), "new()" );
isa_ok( $item1, "Net::Jabber::Stanza" );
isa_ok( $item1, "Net::XMPP::Stanza" );

testScalar($item1,"Email","email");
testScalar($item1,"Family","family");
testScalar($item1,"First","first");
testScalar($item1,"Given","given");
testJID($item1,"JID","user1","server1","resource1");
testScalar($item1,"Key","key");
testScalar($item1,"Last","last");
testScalar($item1,"Name","name");
testScalar($item1,"Nick","nick");

is( $query3->GetXML(), "<query xmlns='jabber:iq:search'><item jid='user1\@server1/resource1'><email>email</email><family>family</family><first>first</first><given>given</given><key>key</key><last>last</last><name>name</name><nick>nick</nick></item></query>", "GetXML()" );

my $item2 = $query3->AddItem(email=>"email",
                             family=>"family",
                             first=>"first",
                             given=>"given",
                             jid=>"user2\@server2/resource2",
                             key=>"key",
                             last=>"last",
                             name=>"name",
                             nick=>"nick",
                            );
ok( defined($item2), "new()" );
isa_ok( $item2, "Net::Jabber::Stanza" );
isa_ok( $item2, "Net::XMPP::Stanza" );

testPostScalar($item2,"Email","email");
testPostScalar($item2,"Family","family");
testPostScalar($item2,"First","first");
testPostScalar($item2,"Given","given");
testPostJID($item2,"JID","user2","server2","resource2");
testPostScalar($item2,"Key","key");
testPostScalar($item2,"Last","last");
testPostScalar($item2,"Name","name");
testPostScalar($item2,"Nick","nick");

is( $query3->GetXML(), "<query xmlns='jabber:iq:search'><item jid='user1\@server1/resource1'><email>email</email><family>family</family><first>first</first><given>given</given><key>key</key><last>last</last><name>name</name><nick>nick</nick></item><item jid='user2\@server2/resource2'><email>email</email><family>family</family><first>first</first><given>given</given><key>key</key><last>last</last><name>name</name><nick>nick</nick></item></query>", "GetXML()" );
                
my @items = $query3->GetItems();
is( $#items, 1, "are there two items?" );
is( $items[0]->GetXML(), "<item jid='user1\@server1/resource1'><email>email</email><family>family</family><first>first</first><given>given</given><key>key</key><last>last</last><name>name</name><nick>nick</nick></item>", "GetXML()" );
is( $items[1]->GetXML(), "<item jid='user2\@server2/resource2'><email>email</email><family>family</family><first>first</first><given>given</given><key>key</key><last>last</last><name>name</name><nick>nick</nick></item>", "GetXML()" );

