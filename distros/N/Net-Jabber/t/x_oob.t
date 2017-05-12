use lib "t/lib";
use Test::More tests=>25;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $x = new Net::Jabber::Stanza("x");
ok( defined($x), "new()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($x,"XMLNS","jabber:x:oob");

testScalar($x,"Desc","desc");
testScalar($x,"URL","url");

is( $x->GetXML(), "<x xmlns='jabber:x:oob'><desc>desc</desc><url>url</url></x>", "GetXML()" );

my $x2 = new Net::Jabber::Stanza("x");
ok( defined($x2), "new()" );
isa_ok( $x2, "Net::Jabber::Stanza" );
isa_ok( $x2, "Net::XMPP::Stanza" );

testScalar($x2,"XMLNS","jabber:x:oob");

$x2->SetOob(desc=>"desc",
            url=>"url");

testPostScalar($x2,"Desc","desc");
testPostScalar($x2,"URL","url");

is( $x2->GetXML(), "<x xmlns='jabber:x:oob'><desc>desc</desc><url>url</url></x>", "GetXML()" );


