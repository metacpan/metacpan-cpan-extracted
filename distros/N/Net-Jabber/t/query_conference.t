use lib "t/lib";
use Test::More tests=>41;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:conference");

testScalar($query,"ID","id");
testScalar($query,"Name","name");
testScalar($query,"Nick","nick");
testFlag($query,"Privacy");
testScalar($query,"Secret","secret");

is( $query->GetXML(), "<query xmlns='jabber:iq:conference'><id>id</id><name>name</name><nick>nick</nick><privacy/><secret>secret</secret></query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:conference");

$query2->SetConference(id=>"id",
                       name=>"name",
                       nick=>"nick",
                       privacy=>1,
                       secret=>"secret");

testPostScalar($query2,"ID","id");
testPostScalar($query2,"Name","name");
testPostScalar($query2,"Nick","nick");
testPostFlag($query2,"Privacy");
testPostScalar($query2,"Secret","secret");

is( $query2->GetXML(), "<query xmlns='jabber:iq:conference'><id>id</id><name>name</name><nick>nick</nick><privacy/><secret>secret</secret></query>", "GetXML()" );

