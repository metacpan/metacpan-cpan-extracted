use lib "t/lib";
use Test::More tests=>36;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:version");

testScalar($query,"Name","name");
testScalar($query,"OS",(&POSIX::uname())[0]);
$query->SetVer("ver");
testPostScalar($query,"Ver","ver - [ Net::Jabber v$Net::Jabber::VERSION ]");

is( $query->GetXML(), "<query xmlns='jabber:iq:version'><name>name</name><os>".(&POSIX::uname())[0]."</os><version>ver - [ Net::Jabber v$Net::Jabber::VERSION ]</version></query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:version");

$query2->SetVersion(name=>"name",
                    os=>"os",
                    ver=>"ver"
                    );

testPostScalar($query2,"Name","name");
testPostScalar($query2,"OS",(&POSIX::uname())[0]);
testPostScalar($query2,"Ver","ver - [ Net::Jabber v$Net::Jabber::VERSION ]");

is( $query2->GetXML(), "<query xmlns='jabber:iq:version'><name>name</name><os>".(&POSIX::uname())[0]."</os><version>ver - [ Net::Jabber v$Net::Jabber::VERSION ]</version></query>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("query");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","jabber:iq:version");

$query3->SetVersion(name=>"test-script",
                    ver=>"v1.03"
                   );

is( $query3->GetXML(), "<query xmlns='jabber:iq:version'><name>test-script</name><os>".(&POSIX::uname())[0]."</os><version>v1.03 - [ Net::Jabber v$Net::Jabber::VERSION ]</version></query>", "GetXML()" );

