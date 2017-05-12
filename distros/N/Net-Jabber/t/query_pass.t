use lib "t/lib";
use Test::More tests=>62;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:pass");

testScalar($query,"Client","client");
testScalar($query,"ClientPort",1234);
testFlag($query,"Close");
testScalar($query,"Expire",10);
testFlag($query,"OneShot");
testScalar($query,"Proxy","proxy");
testScalar($query,"ProxyPort",2345);
testScalar($query,"Server","server");
testScalar($query,"ServerPort",3456);

is( $query->GetXML(), "<query xmlns='jabber:iq:pass'><client port='1234'>client</client><close/><expire>10</expire><oneshot/><proxy port='2345'>proxy</proxy><server port='3456'>server</server></query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:pass");

$query2->SetPass(client=>"client",
                 clientport=>4321,
                 close=>1,
                 expire=>21,
                 oneshot=>1,
                 proxy=>"proxy",
                 proxyport=>5432,
                 server=>"server",
                 serverport=>6543
                );

testPostScalar($query2,"Client","client");
testPostScalar($query2,"ClientPort",4321);
testPostFlag($query2,"Close");
testPostScalar($query2,"Expire",21);
testPostFlag($query2,"OneShot");
testPostScalar($query2,"Proxy","proxy");
testPostScalar($query2,"ProxyPort",5432);
testPostScalar($query2,"Server","server");
testPostScalar($query2,"ServerPort",6543);

is( $query2->GetXML(), "<query xmlns='jabber:iq:pass'><client port='4321'>client</client><close/><expire>21</expire><oneshot/><proxy port='5432'>proxy</proxy><server port='6543'>server</server></query>", "GetXML()" );

