use lib "t/lib";
use Test::More tests=>28;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:last");

testSetScalar($query,"Message","message");
testScalar($query,"Seconds",2000);

is( $query->GetXML(), "<query seconds='2000' xmlns='jabber:iq:last'>message</query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:last");

$query2->SetLast(message=>"message",
                 seconds=>1000
                );

testPostScalar($query2,"Message","message");
testPostScalar($query2,"Seconds",1000);

is( $query2->GetXML(), "<query seconds='1000' xmlns='jabber:iq:last'>message</query>", "GetXML()" );

my %fields = $query2->GetLast();

testFieldScalar(\%fields,"Message","message");
testFieldScalar(\%fields,"Seconds",1000);


