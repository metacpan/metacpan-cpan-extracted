use lib "t/lib";
use Test::More tests=>19;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $client = new Net::Jabber::Client();
ok( defined($client), "new()" );
isa_ok( $client, "Net::Jabber::Client" );

my $query1 = $client->RPCEncode(type=>"methodCall",
                                methodname=>"test_call",
                                params=>["foo",4,{ a=>1, b=>"bar"}]);
ok( defined($query1), "new()" );
isa_ok( $query1, "Net::Jabber::Stanza" );
isa_ok( $query1, "Net::XMPP::Stanza" );

is( $query1->GetXML(), "<query xmlns='jabber:iq:rpc'><methodCall><methodName>test_call</methodName><params><param><value><string>foo</string></value></param><param><value><i4>4</i4></value></param><param><value><struct><member><name>a</name><value><i4>1</i4></value></member><member><name>b</name><value><string>bar</string></value></member></struct></value></param></params></methodCall></query>", "GetXML()" );


my $query2 = $client->RPCEncode(type=>"methodResponse",
                                faultcode=>404,
                                faultstring=>"not found",
                                params=>["foo",4]);
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

is( $query2->GetXML(), "<query xmlns='jabber:iq:rpc'><methodResponse><fault><value><struct><member><name>faultCode</name><value><i4>404</i4></value></member><member><name>faultString</name><value><string>not found</string></value></member></struct></value></fault></methodResponse></query>", "GetXML()" );


my $query3 = $client->RPCEncode(type=>"methodResponse",
                                methodname=>"test_call",
                                params=>["foo",4,{ a=>1, b=>"bar"},["a",1,"foo"]]);
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

is( $query3->GetXML(), "<query xmlns='jabber:iq:rpc'><methodResponse><params><param><value><string>foo</string></value></param><param><value><i4>4</i4></value></param><param><value><struct><member><name>a</name><value><i4>1</i4></value></member><member><name>b</name><value><string>bar</string></value></member></struct></value></param><param><value><array><data><value><string>a</string></value></data><data><value><i4>1</i4></value></data><data><value><string>foo</string></value></data></array></value></param></params></methodResponse></query>", "GetXML()" );


my $query4 = $client->RPCEncode(type=>"methodResponse",
                                methodname=>"test_call",
                                params=>["i4:5",
                                         "boolean:0",
                                         "string:56",
                                         "double:5.0",
                                         "datetime:20020415T11:11:11",
                                         "base64:...."
                                         ]
                               );
ok( defined($query4), "new()" );
isa_ok( $query4, "Net::Jabber::Stanza" );
isa_ok( $query4, "Net::XMPP::Stanza" );

is( $query4->GetXML(), "<query xmlns='jabber:iq:rpc'><methodResponse><params><param><value><i4>5</i4></value></param><param><value><boolean>0</boolean></value></param><param><value><string>56</string></value></param><param><value><double>5.0</double></value></param><param><value><dateTime.iso8601>20020415T11:11:11</dateTime.iso8601></value></param><param><value><base64>....</base64></value></param></params></methodResponse></query>", "GetXML()" );


