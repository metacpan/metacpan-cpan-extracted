use lib "t/lib";
use Test::More tests=>20;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $x = new Net::Jabber::Stanza("x");
ok( defined($x), "new()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($x,"XMLNS","http://jabber.org/protocol/muc");

testScalar($x, "Password", "password");

is( $x->GetXML(), "<x xmlns='http://jabber.org/protocol/muc'><password>password</password></x>", "GetXML()");


my $x2 = new Net::Jabber::Stanza("x");
ok( defined($x2), "new()" );
isa_ok( $x2, "Net::Jabber::Stanza" );
isa_ok( $x2, "Net::XMPP::Stanza" );

testScalar($x2,"XMLNS","http://jabber.org/protocol/muc");

$x2->SetMUC(password=>"password");

testPostScalar($x2, "Password", "password");

is( $x2->GetXML(), "<x xmlns='http://jabber.org/protocol/muc'><password>password</password></x>", "GetXML()");


