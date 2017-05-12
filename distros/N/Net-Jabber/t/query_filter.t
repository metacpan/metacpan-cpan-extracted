use lib "t/lib";
use Test::More tests=>93;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:filter");

my $rule1 = $query->AddRule();
ok( defined($rule1), "new()" );
isa_ok( $rule1, "Net::Jabber::Stanza" );
isa_ok( $rule1, "Net::XMPP::Stanza" );

testScalar($rule1,"Body","body1");
testScalar($rule1,"Continued","continued1");
testScalar($rule1,"Drop","drop1");
testScalar($rule1,"Edit","edit1");
testScalar($rule1,"Error","error1");
testScalar($rule1,"From","from1");
testScalar($rule1,"Offline","offline1");
testScalar($rule1,"Reply","reply1");
testScalar($rule1,"Resource","resource1");
testScalar($rule1,"Show","show1");
testScalar($rule1,"Size","size1");
testScalar($rule1,"Subject","subject1");
testScalar($rule1,"Time","time1");
testScalar($rule1,"Type","type1");
testScalar($rule1,"Unavailable","unavailable1");

is( $query->GetXML(), "<query xmlns='jabber:iq:filter'><rule><body>body1</body><continued>continued1</continued><drop>drop1</drop><edit>edit1</edit><error>error1</error><from>from1</from><offline>offline1</offline><reply>reply1</reply><resource>resource1</resource><show>show1</show><size>size1</size><subject>subject1</subject><time>time1</time><type>type1</type><unavailable>unavailable1</unavailable></rule></query>", "GetXML()" );


my $rule2 = $query->AddRule(body=>"body2",
                            continued=>"continued2",
                            drop=>"drop2",
                            edit=>"edit2",
                            error=>"error2",
                            from=>"from2",
                            offline=>"offline2",
                            reply=>"reply2",
                            resource=>"resource2",
                            show=>"show2",
                            size=>"size2",
                            subject=>"subject2",
                            time=>"time2",
                            type=>"type2",
                            unavailable=>"unavailable2",
                           );
ok( defined($rule2), "new()" );
isa_ok( $rule2, "Net::Jabber::Stanza" );
isa_ok( $rule2, "Net::XMPP::Stanza" );

testPostScalar($rule2,"Body","body2");
testPostScalar($rule2,"Continued","continued2");
testPostScalar($rule2,"Drop","drop2");
testPostScalar($rule2,"Edit","edit2");
testPostScalar($rule2,"Error","error2");
testPostScalar($rule2,"From","from2");
testPostScalar($rule2,"Offline","offline2");
testPostScalar($rule2,"Reply","reply2");
testPostScalar($rule2,"Resource","resource2");
testPostScalar($rule2,"Show","show2");
testPostScalar($rule2,"Size","size2");
testPostScalar($rule2,"Subject","subject2");
testPostScalar($rule2,"Time","time2");
testPostScalar($rule2,"Type","type2");
testPostScalar($rule2,"Unavailable","unavailable2");


is( $query->GetXML(), "<query xmlns='jabber:iq:filter'><rule><body>body1</body><continued>continued1</continued><drop>drop1</drop><edit>edit1</edit><error>error1</error><from>from1</from><offline>offline1</offline><reply>reply1</reply><resource>resource1</resource><show>show1</show><size>size1</size><subject>subject1</subject><time>time1</time><type>type1</type><unavailable>unavailable1</unavailable></rule><rule><body>body2</body><continued>continued2</continued><drop>drop2</drop><edit>edit2</edit><error>error2</error><from>from2</from><offline>offline2</offline><reply>reply2</reply><resource>resource2</resource><show>show2</show><size>size2</size><subject>subject2</subject><time>time2</time><type>type2</type><unavailable>unavailable2</unavailable></rule></query>", "GetXML()" );

my @rules = $query->GetRules();
is( $#rules, 1, "are there two rules?" );
is( $rules[0]->GetXML(), "<rule><body>body1</body><continued>continued1</continued><drop>drop1</drop><edit>edit1</edit><error>error1</error><from>from1</from><offline>offline1</offline><reply>reply1</reply><resource>resource1</resource><show>show1</show><size>size1</size><subject>subject1</subject><time>time1</time><type>type1</type><unavailable>unavailable1</unavailable></rule>", "GetXML()" );
is( $rules[1]->GetXML(), "<rule><body>body2</body><continued>continued2</continued><drop>drop2</drop><edit>edit2</edit><error>error2</error><from>from2</from><offline>offline2</offline><reply>reply2</reply><resource>resource2</resource><show>show2</show><size>size2</size><subject>subject2</subject><time>time2</time><type>type2</type><unavailable>unavailable2</unavailable></rule>", "GetXML()" );

