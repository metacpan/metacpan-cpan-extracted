use lib "t/lib";
use Test::More tests=>91;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:agent");

testFlag($query,"Agents");
testScalar($query,"Description","this is something");
testJID($query,"JID","user","server","resource");
testFlag($query,"GroupChat");
testScalar($query,"Name","name");
testFlag($query,"Register");
testFlag($query,"Search");
testScalar($query,"Service","service");
testScalar($query,"Transport","transport");
testScalar($query,"URL","url");

is( $query->GetXML(), "<query jid='user\@server/resource' xmlns='jabber:iq:agent'><agents/><description>this is something</description><groupchat/><name>name</name><register/><search/><service>service</service><transport>transport</transport><url>url</url></query>", "GetXML()");


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:agent");

testNotDefined($query2,"Agents");
testNotDefined($query2,"Description");
testNotDefined($query2,"JID");
testNotDefined($query2,"Name");
testNotDefined($query2,"GroupChat");
testNotDefined($query2,"Register");
testNotDefined($query2,"Search");
testNotDefined($query2,"Service");
testNotDefined($query2,"Transport");
testNotDefined($query2,"URL");

$query2->SetAgent(agents=>1,
                  description=>"this is something",
                  jid=>"user\@server/resource",
                  name=>"name",
                  groupchat=>1,
                  register=>1,
                  search=>1,
                  service=>"service",
                  transport=>"transport",
                  url=>"url");

testPostFlag($query2,"Agents");
testPostScalar($query2,"Description","this is something");
testPostJID($query2,"JID","user","server","resource");
testPostScalar($query2,"Name","name");
testPostFlag($query2,"GroupChat");
testPostFlag($query2,"Register");
testPostFlag($query2,"Search");
testPostScalar($query2,"Service","service");
testPostScalar($query2,"Transport","transport");
testPostScalar($query2,"URL","url");

is( $query2->GetXML(), "<query jid='user\@server/resource' xmlns='jabber:iq:agent'><agents/><description>this is something</description><groupchat/><name>name</name><register/><search/><service>service</service><transport>transport</transport><url>url</url></query>", "GetXML()");

