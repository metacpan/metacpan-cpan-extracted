use lib "t/lib";
use Test::More tests=>24;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $message_node = new XML::Stream::Node("message");
ok( defined($message_node), "new()");
isa_ok( $message_node, "XML::Stream::Node" );

$message_node->put_attrib(to=>"jer\@jabber.org",
                          from=>"reatmon\@jabber.org");
my $body_node = $message_node->add_child("body");
$body_node->add_cdata("body");
my $subject_node = $message_node->add_child("subject");
$subject_node->add_cdata("subject");

my $xdelay1 = $message_node->add_child("x");
$xdelay1->put_attrib(xmlns=>"jabber:x:delay",
                    from=>"jabber.org",
                    stamp=>"stamp",
                    );
$xdelay1->add_cdata("Delay1");

my $xdelay2 = $message_node->add_child("x");
$xdelay2->put_attrib(xmlns=>"jabber:x:delay",
                     from=>"jabber.org",
                     stamp=>"stamp",
                     );
$xdelay2->add_cdata("Delay2");

is( $message_node->GetXML(), "<message from='reatmon\@jabber.org' to='jer\@jabber.org'><body>body</body><subject>subject</subject><x from='jabber.org' stamp='stamp' xmlns='jabber:x:delay'>Delay1</x><x from='jabber.org' stamp='stamp' xmlns='jabber:x:delay'>Delay2</x></message>", "GetXML()" );

my $message = new Net::Jabber::Message($message_node);
ok( defined($message), "new()" );
isa_ok( $message, "Net::Jabber::Message" );
isa_ok( $message, "Net::XMPP::Message" );

is( $message->GetTo(), "jer\@jabber.org", "GetTo");
is( $message->GetFrom(), "reatmon\@jabber.org", "GetFrom");
is( $message->GetSubject(), "subject", "GetSubject");
is( $message->GetBody(), "body", "GetBody");

my @xdelays = $message->GetChild("jabber:x:delay");
is( $#xdelays, 1, "two delays");

$xdelay1 = $xdelays[0];
ok( defined($xdelay1), "defined delay" );
isa_ok( $xdelay1, "Net::Jabber::Stanza" );
isa_ok( $xdelay1, "Net::XMPP::Stanza" );

is( $xdelay1->GetFrom(), "jabber.org", "GetFrom");
is( $xdelay1->GetStamp(), "stamp", "GetStamp");
is( $xdelay1->GetMessage(), "Delay1", "GetMessage");

$xdelay2 = $xdelays[1];
ok( defined($xdelay2), "defined delay" );
isa_ok( $xdelay2, "Net::Jabber::Stanza" );
isa_ok( $xdelay2, "Net::XMPP::Stanza" );

is( $xdelay2->GetFrom(), "jabber.org", "GetFrom");
is( $xdelay2->GetStamp(), "stamp", "GetStamp");
is( $xdelay2->GetMessage(), "Delay2", "GetMessage");

