use lib "t/lib";
use Test::More tests=>28;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $message_node = new XML::Stream::Node("message");
ok( defined($message_node), "new()" );
isa_ok( $message_node, "XML::Stream::Node" );

$message_node->put_attrib(to=>"jer\@jabber.org",
                          from=>"reatmon\@jabber.org");
my $body_node = $message_node->add_child("body");
$body_node->add_cdata("body");
my $subject_node = $message_node->add_child("subject");
$subject_node->add_cdata("subject");

my $xdata = $message_node->add_child("x");
$xdata->put_attrib(xmlns=>"jabber:x:data");
$xdata->add_child("instructions","fill this out");
my $field1 = $xdata->add_child("field");
$field1->put_attrib(type=>"hidden",
                    var=>"formnum");
$field1->add_child("value","value1");

my $field2 = $xdata->add_child("field");
$field2->put_attrib(type=>"list-single",
                    var=>"mylist");
$field2->add_child("value","male");
$field2->add_child("value","test");
$field2->add_child("required");
my $option1 = $field2->add_child("option");
$option1->put_attrib(label=>"Male");
$option1->add_child("value","male");
my $option2 = $field2->add_child("option");
$option2->put_attrib(label=>"Female");
$option2->add_child("value","female");

is( $message_node->GetXML(), "<message from='reatmon\@jabber.org' to='jer\@jabber.org'><body>body</body><subject>subject</subject><x xmlns='jabber:x:data'><instructions>fill this out</instructions><field type='hidden' var='formnum'><value>value1</value></field><field type='list-single' var='mylist'><value>male</value><value>test</value><required/><option label='Male'><value>male</value></option><option label='Female'><value>female</value></option></field></x></message>", "GetXML()" );

my $message = new Net::Jabber::Message($message_node);
ok( defined($message), "new()" );
isa_ok( $message, "Net::Jabber::Message" );
isa_ok( $message, "Net::XMPP::Message" );

is( $message->GetTo(), "jer\@jabber.org", "GetTo");
is( $message->GetFrom(), "reatmon\@jabber.org", "GetFrom");
is( $message->GetSubject(), "subject", "GetSubject");
is( $message->GetBody(), "body", "GetBody");

my @xdatas = $message->GetChild("jabber:x:data");
is( $#xdatas, 0, "one data packet" );

my $xdata1 = $xdatas[0];
ok( defined($xdata1), "defined data" );
isa_ok( $xdata1, "Net::Jabber::Stanza" );
isa_ok( $xdata1, "Net::XMPP::Stanza" );

is( $xdata1->GetInstructions(), "fill this out", "GetInsructions" );

my @fields = $xdata1->GetFields();
is( $#fields, 1, "two fields");

my $listField = $fields[1];
is( $listField->GetVar(), "mylist", "GetVar");
is( $listField->GetType(), "list-single", "GetType");

my @values = $listField->GetValue();
is( $#values, 1, "two values");
is( $values[0], "male", "value == male");
is( $values[1], "test", "value == test");

ok( $listField->GetRequired(), "GetRequired");

my @options = $listField->GetOptions();
is( $#options, 1, "two options");

my $listOption1 = $options[0];
my $listOption2 = $options[1];

is( $listOption1->GetLabel(), "Male", "GetLabel");
is( $listOption1->GetValue(), "male", "Getvalue");
is( $listOption2->GetLabel(), "Female", "GetLabel");
is( $listOption2->GetValue(), "female", "GetValue");

