use lib "t/lib";
use Test::More tests=>97;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("query");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","jabber:iq:autoupdate");

my $dev = $query->AddDev();
ok( defined($dev), "new()" );
isa_ok( $dev, "Net::Jabber::Stanza" );
isa_ok( $dev, "Net::XMPP::Stanza" );

testScalar($dev,"Desc","desc");
testScalar($dev,"Priority","priority");
testScalar($dev,"URL","url");
testScalar($dev,"Version","version");

my $beta = $query->AddBeta();
ok( defined($beta), "new()" );
isa_ok( $beta, "Net::Jabber::Stanza" );
isa_ok( $beta, "Net::XMPP::Stanza" );

testScalar($beta,"Desc","desc");
testScalar($beta,"Priority","priority");
testScalar($beta,"URL","url");
testScalar($beta,"Version","version");

my $release = $query->AddRelease();
ok( defined($release), "new()" );
isa_ok( $release, "Net::Jabber::Stanza" );
isa_ok( $release, "Net::XMPP::Stanza" );

testScalar($release,"Desc","desc");
testScalar($release,"Priority","priority");
testScalar($release,"URL","url");
testScalar($release,"Version","version");

is( $query->GetXML(), "<query xmlns='jabber:iq:autoupdate'><dev priority='priority'><desc>desc</desc><url>url</url><version>version</version></dev><beta priority='priority'><desc>desc</desc><url>url</url><version>version</version></beta><release priority='priority'><desc>desc</desc><url>url</url><version>version</version></release></query>", "GetXML()" );


my $query2 = new Net::Jabber::Stanza("query");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","jabber:iq:autoupdate");

my $dev2 = $query2->AddDev(desc=>"desc",
                           priority=>"priority",
                           url=>"url",
                           version=>"version");
ok( defined($dev2), "new()" );
isa_ok( $dev2, "Net::Jabber::Stanza" );
isa_ok( $dev2, "Net::XMPP::Stanza" );

testPostScalar($dev2,"Desc","desc");
testPostScalar($dev2,"Priority","priority");
testPostScalar($dev2,"URL","url");
testPostScalar($dev2,"Version","version");

my $beta2 = $query2->AddBeta(desc=>"desc",
                             priority=>"priority",
                             url=>"url",
                             version=>"version");
ok( defined($beta2), "new()" );
isa_ok( $beta2, "Net::Jabber::Stanza" );
isa_ok( $beta2, "Net::XMPP::Stanza" );

testPostScalar($beta2,"Desc","desc");
testPostScalar($beta2,"Priority","priority");
testPostScalar($beta2,"URL","url");
testPostScalar($beta2,"Version","version");

my $release2 = $query2->AddRelease(desc=>"desc",
                                   priority=>"priority",
                                   url=>"url",
                                   version=>"version");
ok( defined($release2), "new()" );
isa_ok( $release2, "Net::Jabber::Stanza" );
isa_ok( $release2, "Net::XMPP::Stanza" );

testPostScalar($release2,"Desc","desc");
testPostScalar($release2,"Priority","priority");
testPostScalar($release2,"URL","url");
testPostScalar($release2,"Version","version");

is( $query2->GetXML(), "<query xmlns='jabber:iq:autoupdate'><dev priority='priority'><desc>desc</desc><url>url</url><version>version</version></dev><beta priority='priority'><desc>desc</desc><url>url</url><version>version</version></beta><release priority='priority'><desc>desc</desc><url>url</url><version>version</version></release></query>", "GetXML()" );

my @releases = $query2->GetReleases();
is( $#releases, 2, "are there three releases?" );
is( $releases[0]->GetXML(), "<dev priority='priority'><desc>desc</desc><url>url</url><version>version</version></dev>", "GetXML()" );
is( $releases[1]->GetXML(), "<beta priority='priority'><desc>desc</desc><url>url</url><version>version</version></beta>", "GetXML()" );
is( $releases[2]->GetXML(), "<release priority='priority'><desc>desc</desc><url>url</url><version>version</version></release>", "GetXML()" );


