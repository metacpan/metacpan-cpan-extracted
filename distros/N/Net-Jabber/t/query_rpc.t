use lib "t/lib";
use Test::More tests=>217;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:rpc");

my $methodCall = $query->AddMethodCall();
ok( defined($methodCall), "new()" );
isa_ok( $methodCall, "Net::Jabber::Stanza" );
isa_ok( $methodCall, "Net::XMPP::Stanza" );

ok( $query->DefinedMethodCall(), "DefinedMethodCall()" );

testScalar($methodCall, "MethodName", "method_name");

my $params = $methodCall->AddParams();
ok( defined($params), "new()" );
isa_ok( $params, "Net::Jabber::Stanza" );
isa_ok( $params, "Net::XMPP::Stanza" );


my $param1 = $params->AddParam();
ok( defined($param1), "new()" );
isa_ok( $param1, "Net::Jabber::Stanza" );
isa_ok( $param1, "Net::XMPP::Stanza" );

my $value1_1 = $param1->AddValue();
ok( defined($value1_1), "new()" );
isa_ok( $value1_1, "Net::Jabber::Stanza" );
isa_ok( $value1_1, "Net::XMPP::Stanza" );

testScalar($value1_1, "Base64", "value");
testScalar($value1_1, "Boolean", "value");
testScalar($value1_1, "DateTime", "value");
testScalar($value1_1, "Double", "value");
testScalar($value1_1, "I4", "value");
testScalar($value1_1, "Int", "value");
testScalar($value1_1, "String", "value");
testScalar($value1_1, "Value", "value");

my $struct1 = $value1_1->AddStruct();

my $member1 = $struct1->AddMember();
ok( defined($member1), "new()" );
isa_ok( $member1, "Net::Jabber::Stanza" );
isa_ok( $member1, "Net::XMPP::Stanza" );

testScalar($member1, "Name", "name");

my $member1_value1 = $member1->AddValue();
ok( defined($member1_value1), "new()" );
isa_ok( $member1_value1, "Net::Jabber::Stanza" );
isa_ok( $member1_value1, "Net::XMPP::Stanza" );

testScalar($member1_value1, "Base64", "base64");
testScalar($member1_value1, "Boolean", "boolean");
testScalar($member1_value1, "DateTime", "datetime");
testScalar($member1_value1, "Double", "double");
testScalar($member1_value1, "I4", "i4");
testScalar($member1_value1, "Int", "int");
testScalar($member1_value1, "String", "string");
testScalar($member1_value1, "Value", "value");

my $array1 = $value1_1->AddArray();

my $data1 = $array1->AddData();
ok( defined($data1), "new()" );
isa_ok( $data1, "Net::Jabber::Stanza" );
isa_ok( $data1, "Net::XMPP::Stanza" );

my $data1_value1 = $data1->AddValue();
ok( defined($data1_value1), "new()" );
isa_ok( $data1_value1, "Net::Jabber::Stanza" );
isa_ok( $data1_value1, "Net::XMPP::Stanza" );

testScalar($data1_value1, "Base64", "base64");
testScalar($data1_value1, "Boolean", "boolean");
testScalar($data1_value1, "DateTime", "datetime");
testScalar($data1_value1, "Double", "double");
testScalar($data1_value1, "I4", "i4");
testScalar($data1_value1, "Int", "int");
testScalar($data1_value1, "String", "string");
testScalar($data1_value1, "Value", "value");

is( $query->GetXML(), "<query xmlns='jabber:iq:rpc'><methodCall><methodName>method_name</methodName><params><param><value><base64>value</base64><boolean>value</boolean><dateTime.iso8601>value</dateTime.iso8601><double>value</double><i4>value</i4><int>value</int><string>value</string><value>value</value><struct><member><name>name</name><value><base64>base64</base64><boolean>boolean</boolean><dateTime.iso8601>datetime</dateTime.iso8601><double>double</double><i4>i4</i4><int>int</int><string>string</string><value>value</value></value></member></struct><array><data><value><base64>base64</base64><boolean>boolean</boolean><dateTime.iso8601>datetime</dateTime.iso8601><double>double</double><i4>i4</i4><int>int</int><string>string</string><value>value</value></value></data></array></value></param></params></methodCall></query>", "GetXML()" );


my $methodResponse = $query->AddMethodResponse();
ok( defined($methodResponse), "new()" );
isa_ok( $methodResponse, "Net::Jabber::Stanza" );
isa_ok( $methodResponse, "Net::XMPP::Stanza" );

my $params2 = $methodResponse->AddParams();
ok( defined($params2), "new()" );
isa_ok( $params2, "Net::Jabber::Stanza" );
isa_ok( $params2, "Net::XMPP::Stanza" );

my $param2 = $params2->AddParam();
ok( defined($param2), "new()" );
isa_ok( $param2, "Net::Jabber::Stanza" );
isa_ok( $param2, "Net::XMPP::Stanza" );

my $value2_1 = $param2->AddValue();
ok( defined($value2_1), "new()" );
isa_ok( $value2_1, "Net::Jabber::Stanza" );
isa_ok( $value2_1, "Net::XMPP::Stanza" );

testScalar($value2_1, "Base64", "value");
testScalar($value2_1, "Boolean", "value");
testScalar($value2_1, "DateTime", "value");
testScalar($value2_1, "Double", "value");
testScalar($value2_1, "I4", "value");
testScalar($value2_1, "Int", "value");
testScalar($value2_1, "String", "value");
testScalar($value2_1, "Value", "value");

my $struct2 = $value2_1->AddStruct();

my $member2 = $struct2->AddMember();
ok( defined($member2), "new()" );
isa_ok( $member2, "Net::Jabber::Stanza" );
isa_ok( $member2, "Net::XMPP::Stanza" );

testScalar($member2, "Name", "name");

my $member2_value1 = $member2->AddValue();
ok( defined($member2_value1), "new()" );
isa_ok( $member2_value1, "Net::Jabber::Stanza" );
isa_ok( $member2_value1, "Net::XMPP::Stanza" );

testScalar($member2_value1, "Base64", "base64");
testScalar($member2_value1, "Boolean", "boolean");
testScalar($member2_value1, "DateTime", "datetime");
testScalar($member2_value1, "Double", "double");
testScalar($member2_value1, "I4", "i4");
testScalar($member2_value1, "Int", "int");
testScalar($member2_value1, "String", "string");
testScalar($member2_value1, "Value", "value");

my $array2 = $value2_1->AddArray();

my $data2 = $array2->AddData();
ok( defined($data2), "new()" );
isa_ok( $data2, "Net::Jabber::Stanza" );
isa_ok( $data2, "Net::XMPP::Stanza" );

my $data2_value1 = $data2->AddValue();
ok( defined($data2_value1), "new()" );
isa_ok( $data2_value1, "Net::Jabber::Stanza" );
isa_ok( $data2_value1, "Net::XMPP::Stanza" );

testScalar($data2_value1, "Base64", "base64");
testScalar($data2_value1, "Boolean", "boolean");
testScalar($data2_value1, "DateTime", "datetime");
testScalar($data2_value1, "Double", "double");
testScalar($data2_value1, "I4", "i4");
testScalar($data2_value1, "Int", "int");
testScalar($data2_value1, "String", "string");
testScalar($data2_value1, "Value", "value");

my $fault1 = $methodResponse->AddFault();
ok( defined($fault1), "new()" );
isa_ok( $fault1, "Net::Jabber::Stanza" );
isa_ok( $fault1, "Net::XMPP::Stanza" );

my $faultStruct = $fault1->AddValue()->AddStruct();
ok( defined($faultStruct), "new()" );
isa_ok( $faultStruct, "Net::Jabber::Stanza" );
isa_ok( $faultStruct, "Net::XMPP::Stanza" );

$faultStruct->AddMember(name=>"faultCode")->AddValue(i4=>404);
$faultStruct->AddMember(name=>"faultString")->AddValue(string=>"not found");


is( $query->GetXML(), "<query xmlns='jabber:iq:rpc'><methodCall><methodName>method_name</methodName><params><param><value><base64>value</base64><boolean>value</boolean><dateTime.iso8601>value</dateTime.iso8601><double>value</double><i4>value</i4><int>value</int><string>value</string><value>value</value><struct><member><name>name</name><value><base64>base64</base64><boolean>boolean</boolean><dateTime.iso8601>datetime</dateTime.iso8601><double>double</double><i4>i4</i4><int>int</int><string>string</string><value>value</value></value></member></struct><array><data><value><base64>base64</base64><boolean>boolean</boolean><dateTime.iso8601>datetime</dateTime.iso8601><double>double</double><i4>i4</i4><int>int</int><string>string</string><value>value</value></value></data></array></value></param></params></methodCall><methodResponse><params><param><value><base64>value</base64><boolean>value</boolean><dateTime.iso8601>value</dateTime.iso8601><double>value</double><i4>value</i4><int>value</int><string>value</string><value>value</value><struct><member><name>name</name><value><base64>base64</base64><boolean>boolean</boolean><dateTime.iso8601>datetime</dateTime.iso8601><double>double</double><i4>i4</i4><int>int</int><string>string</string><value>value</value></value></member></struct><array><data><value><base64>base64</base64><boolean>boolean</boolean><dateTime.iso8601>datetime</dateTime.iso8601><double>double</double><i4>i4</i4><int>int</int><string>string</string><value>value</value></value></data></array></value></param></params><fault><value><struct><member><name>faultCode</name><value><i4>404</i4></value></member><member><name>faultString</name><value><string>not found</string></value></member></struct></value></fault></methodResponse></query>", "GetXML()" );


