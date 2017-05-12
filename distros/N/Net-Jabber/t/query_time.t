use lib "t/lib";
use Test::More tests=>39;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:time");

testScalar($query,"Display","display");
testScalar($query,"TZ","tz");
testScalar($query,"UTC","utc");

is( $query->GetXML(), "<query xmlns='jabber:iq:time'><display>display</display><tz>tz</tz><utc>utc</utc></query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:time");

$query2->SetTime(display=>"display",
                 tz=>"tz",
                 utc=>"utc"
                );

testPostScalar($query2,"Display","display");
testPostScalar($query2,"TZ","tz");
testPostScalar($query2,"UTC","utc");

is( $query2->GetXML(), "<query xmlns='jabber:iq:time'><display>display</display><tz>tz</tz><utc>utc</utc></query>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("query");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","jabber:iq:time");

$query3->SetTime();

like( $query3->GetUTC(), qr/^\d\d\d\d\d\d\d\dT\d\d:\d\d:\d\d$/, "look like a utc?" );
like( $query3->GetDisplay(), qr/^\w\w\w \w\w\w \d\d, \d\d\d\d \d\d:\d\d:\d\d$/, "look like a display?" );

SKIP:
{
    eval("use Time::Timezone 99.062401;");
    skip "Time::Timezone not installed", 1 if $@;

    like( $query3->GetTZ(), qr/^\S+$/, "look like a timezone?" );
}


