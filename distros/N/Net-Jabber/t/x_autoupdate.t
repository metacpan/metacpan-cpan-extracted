use lib "t/lib";
use Test::More tests=>32;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $x = new Net::Jabber::Stanza("x");
ok( defined($x), "new()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($x,"XMLNS","jabber:x:autoupdate");

testJID($x, "JID", "user", "server", "resource");

is( $x->GetXML(), "<x jid='user\@server/resource' xmlns='jabber:x:autoupdate'/>", "GetXML()" );

my $x2 = new Net::Jabber::Stanza("x");
ok( defined($x2), "new()" );
isa_ok( $x2, "Net::Jabber::Stanza" );
isa_ok( $x2, "Net::XMPP::Stanza" );

testScalar($x2,"XMLNS","jabber:x:autoupdate");

$x2->SetAutoupdate(jid=>"user\@server/resource");

testPostJID($x2, "JID", "user", "server", "resource");

is( $x2->GetXML(), "<x jid='user\@server/resource' xmlns='jabber:x:autoupdate'/>", "GetXML()" );

