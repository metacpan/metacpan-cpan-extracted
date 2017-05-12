use lib "t/lib";
use Test::More tests=>4;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $client = new Net::Jabber::Client();
ok( defined($client), "new()" );
isa_ok( $client, "Net::Jabber::Client" );

my $presence_xml = $client->MUCJoin(room=>"test1",
                                    server=>"test2",
                                    nick=>"test3",
                                    '__netjabber__:test'=>1);
is( $presence_xml, "<presence to='test1\@test2/test3'><x xmlns='http://jabber.org/protocol/muc'/></presence>", "GetXML()");

