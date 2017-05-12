use lib "t/lib";
use Test::More tests=>19;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $x = new Net::Jabber::Stanza("x");
ok( defined($x), "new()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($x,"XMLNS","jabber:x:encrypted");

testSetScalar($x,"Message","message");

is( $x->GetXML(), "<x xmlns='jabber:x:encrypted'>message</x>", "GetXML()");

my $x2 = new Net::Jabber::Stanza("x");
ok( defined($x2), "new()" );
isa_ok( $x2, "Net::Jabber::Stanza" );
isa_ok( $x2, "Net::XMPP::Stanza" );

testScalar($x2,"XMLNS","jabber:x:encrypted");

$x2->SetEncrypted(message=>"message");

testPostScalar($x2,"Message","message");

is( $x2->GetXML(), "<x xmlns='jabber:x:encrypted'>message</x>", "GetXML()");

