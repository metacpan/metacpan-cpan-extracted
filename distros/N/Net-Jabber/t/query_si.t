use lib "t/lib";
use Test::More tests=>44;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("si");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","http://jabber.org/protocol/si");

testScalar($query,"ID","id");
testScalar($query,"MimeType","mimetype");
testScalar($query,"Profile","profile");

is( $query->GetXML(), "<si id='id' mime-type='mimetype' profile='profile' xmlns='http://jabber.org/protocol/si'/>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("si");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","http://jabber.org/protocol/si");

$query2->SetStream(id=>"id",
                   mimetype=>"mimetype",
                   profile=>"profile"
                  );

testPostScalar($query2,"ID","id");
testPostScalar($query2,"MimeType","mimetype");
testPostScalar($query2,"Profile","profile");

is( $query2->GetXML(), "<si id='id' mime-type='mimetype' profile='profile' xmlns='http://jabber.org/protocol/si'/>", "GetXML()" );


my $iq = new Net::Jabber::IQ();
ok( defined($iq), "new()" );
isa_ok( $iq, "Net::Jabber::IQ" );

my $query3 = $iq->NewChild("http://jabber.org/protocol/si");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testPostScalar($query3,"XMLNS","http://jabber.org/protocol/si");

$query3->SetStream(id=>"id",
                   mimetype=>"mimetype",
                   profile=>"profile"
                  );

testPostScalar($query3,"ID","id");
testPostScalar($query3,"MimeType","mimetype");
testPostScalar($query3,"Profile","profile");

is( $iq->GetXML(), "<iq><si id='id' mime-type='mimetype' profile='profile' xmlns='http://jabber.org/protocol/si'/></iq>", "GetXML()" );


