use lib "t/lib";
use Test::More tests=>100;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("si");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","http://jabber.org/protocol/si");

testScalar($query,"Profile","http://jabber.org/protocol/si/profile/file-transfer");

my $prof = $query->NewChild("http://jabber.org/protocol/si/profile/file-transfer");

testScalar($prof,"Date","date");
testScalar($prof,"Desc","desc");
testScalar($prof,"Hash","hash");
testScalar($prof,"Name","name");
testScalar($prof,"RangeLength","length");
testScalar($prof,"RangeOffset","offest");
testScalar($prof,"Size","size");

is( $query->GetXML(), "<si profile='http://jabber.org/protocol/si/profile/file-transfer' xmlns='http://jabber.org/protocol/si'><file date='date' hash='hash' name='name' size='size' xmlns='http://jabber.org/protocol/si/profile/file-transfer'><desc>desc</desc><range length='length' offset='offest'/></file></si>", "GetXML()" );

my $query2 = new Net::Jabber::Stanza("si");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","http://jabber.org/protocol/si");

testScalar($query2,"Profile","http://jabber.org/protocol/si/profile/file-transfer");

my $prof2 = $query2->NewChild("http://jabber.org/protocol/si/profile/file-transfer");

testScalar($prof2,"Date","date");
testScalar($prof2,"Hash","hash");
testScalar($prof2,"Name","name");
testFlag($prof2,"Range");
testScalar($prof2,"Size","size");

is( $query2->GetXML(), "<si profile='http://jabber.org/protocol/si/profile/file-transfer' xmlns='http://jabber.org/protocol/si'><file date='date' hash='hash' name='name' size='size' xmlns='http://jabber.org/protocol/si/profile/file-transfer'><range/></file></si>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("si");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","http://jabber.org/protocol/si");

$query3->SetStream(profile=>"http://jabber.org/protocol/si/profile/file-transfer");

testPostScalar($query3,"Profile","http://jabber.org/protocol/si/profile/file-transfer");

my $prof3 = $query3->NewChild("http://jabber.org/protocol/si/profile/file-transfer");

$prof3->SetFile(date=>"date",
                desc=>"desc",
                hash=>"hash",
                name=>"name",
                rangelength=>"length",
                rangeoffset=>"offset",
                size=>"size"
               );

testPostScalar($prof3,"Date","date");
testPostScalar($prof3,"Desc","desc");
testPostScalar($prof3,"Hash","hash");
testPostScalar($prof3,"Name","name");
testPostScalar($prof3,"RangeLength","length");
testPostScalar($prof3,"RangeOffset","offset");
testPostScalar($prof3,"Size","size");

is( $query3->GetXML(), "<si profile='http://jabber.org/protocol/si/profile/file-transfer' xmlns='http://jabber.org/protocol/si'><file date='date' hash='hash' name='name' size='size' xmlns='http://jabber.org/protocol/si/profile/file-transfer'><desc>desc</desc><range length='length' offset='offset'/></file></si>", "GetXML()" );


my $query4 = new Net::Jabber::Stanza("si");
ok( defined($query4), "new()" );
isa_ok( $query4, "Net::Jabber::Stanza" );
isa_ok( $query4, "Net::XMPP::Stanza" );

testScalar($query4,"XMLNS","http://jabber.org/protocol/si");

$query4->SetStream(profile=>"http://jabber.org/protocol/si/profile/file-transfer");

testPostScalar($query4,"Profile","http://jabber.org/protocol/si/profile/file-transfer");

my $prof4 = $query4->NewChild("http://jabber.org/protocol/si/profile/file-transfer");

$prof4->SetFile(date=>"date",
                hash=>"hash",
                name=>"name",
                range=>1,
                size=>"size"
               );

testPostScalar($prof4,"Date","date");
testPostScalar($prof4,"Hash","hash");
testPostScalar($prof4,"Name","name");
testPostFlag($prof4,"Range");
testPostScalar($prof4,"Size","size");

is( $query4->GetXML(), "<si profile='http://jabber.org/protocol/si/profile/file-transfer' xmlns='http://jabber.org/protocol/si'><file date='date' hash='hash' name='name' size='size' xmlns='http://jabber.org/protocol/si/profile/file-transfer'><range/></file></si>", "GetXML()" );

