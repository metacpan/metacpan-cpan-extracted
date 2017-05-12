use lib "t/lib";
use Test::More tests=>155;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $x = new Net::Jabber::Stanza("x");
ok( defined($x), "new()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($x, "XMLNS", "jabber:x:data");

testScalar($x, "Instructions", "do this");
testScalar($x, "Title", "title");
testScalar($x, "Type", "type");

my $field = $x->AddField();
ok( defined($field), "AddField()" );
isa_ok( $field, "Net::Jabber::Stanza" );
isa_ok( $field, "Net::XMPP::Stanza" );

testScalar($field, "Desc", "desc");
testScalar($field, "Label", "label");

testFlag($field, "Required");

testScalar($field, "Type", "type");
testScalar($field, "Value", "value");
testScalar($field, "Var", "var");

$field->SetValue("value2");
my @values = $field->GetValue();
is( $values[0], "value", "check value 1" );
is( $values[1], "value2", "check value 2" );

my $option = $field->AddOption();
ok( defined($option), "AddOption()" );
isa_ok( $option, "Net::Jabber::Stanza" );
isa_ok( $option, "Net::XMPP::Stanza" );

testScalar($option, "Label", "label");
testScalar($option, "Value", "value");

my $field2 = $x->AddField();
ok( defined($field2), "AddField()" );
isa_ok( $field2, "Net::Jabber::Stanza" );
isa_ok( $field2, "Net::XMPP::Stanza" );

my $option2 = $field2->AddOption();
ok( defined($option2), "AddOption()" );
isa_ok( $option2, "Net::Jabber::Stanza" );
isa_ok( $option2, "Net::XMPP::Stanza" );

my @testFields = $x->GetFields();
is( $#testFields, 1, "Only two fields...");

my $testField = $testFields[0];

testPostScalar($testField, "Desc", "desc");
testPostScalar($testField, "Label", "label");

is( $testField->DefinedRequired(), 1, "required defined" );
ok( $testField->GetRequired(), "required" );

testPostScalar($testField, "Type", "type");
testPostScalar($testField, "Var", "var");

my @testOptions = $testField->GetOptions();
is( $#testOptions, 0, "Only two options...");

my $testOption = $testOptions[0];

testPostScalar($testOption, "Label", "label");
testPostScalar($testOption, "Value", "value");

is( $x->GetXML(), "<x type='type' xmlns='jabber:x:data'><instructions>do this</instructions><title>title</title><field label='label' type='type' var='var'><desc>desc</desc><required/><value>value</value><value>value2</value><option label='label'><value>value</value></option></field><field><option/></field></x>", "GetXML()" );



my $x2 = new Net::Jabber::Stanza("x");
ok( defined($x2), "new()" );
isa_ok( $x2, "Net::Jabber::Stanza" );
isa_ok( $x2, "Net::XMPP::Stanza" );

testScalar($x2, "XMLNS", "jabber:x:data");

$x2->SetData(instructions=>"do this",
             title=>"title",
             type=>"type");

testPostScalar($x2, "Instructions", "do this");
testPostScalar($x2, "Title", "title");
testPostScalar($x2, "Type", "type");

my $field3 = $x2->AddField();
ok( defined($field3), "AddField()" );
isa_ok( $field3, "Net::Jabber::Stanza" );
isa_ok( $field3, "Net::XMPP::Stanza" );

testNotDefined($field3, "Desc");
testNotDefined($field3, "Label");
testNotDefined($field3, "Required");
testNotDefined($field3, "Type");
testNotDefined($field3, "Value");
testNotDefined($field3, "Var");

$field3->SetField(desc=>"desc",
                  label=>"label",
                  required=>1,
                  type=>"type",
                  value=>"value",
                  var=>"var");


testPostScalar($field3, "Desc", "desc");
testPostScalar($field3, "Label", "label");
testPostFlag($field3, "Required");
testPostScalar($field3, "Type", "type");
testPostScalar($field3, "Value", "value");
testPostScalar($field3, "Var", "var");

my $option3 = $field3->AddOption();
ok( defined($option3), "AddOption()" );
isa_ok( $option3, "Net::Jabber::Stanza" );
isa_ok( $option3, "Net::XMPP::Stanza" );

testNotDefined($option3, "Label");
testNotDefined($option3, "Value");

$option3->SetOption(label=>"label",
                    value=>"value");

testPostScalar($option3, "Label", "label");
testPostScalar($option3, "Value", "value");

is( $x2->GetXML(), "<x type='type' xmlns='jabber:x:data'><instructions>do this</instructions><title>title</title><field label='label' type='type' var='var'><desc>desc</desc><required/><value>value</value><option label='label'><value>value</value></option></field></x>", "GetXML()" );


my $x3 = new Net::Jabber::Stanza("x");
ok( defined($x3), "new()" );
isa_ok( $x3, "Net::Jabber::Stanza" );
isa_ok( $x3, "Net::XMPP::Stanza" );

testScalar($x3, "XMLNS", "jabber:x:data");

my $reported = $x3->AddReported();
ok( defined($reported), "new()" );
isa_ok( $reported, "Net::Jabber::Stanza" );
isa_ok( $reported, "Net::XMPP::Stanza" );

ok( defined($x3), "new()" );
isa_ok( $x3, "Net::Jabber::Stanza" );
isa_ok( $x3, "Net::XMPP::Stanza" );

$reported->AddField(var=>"var1",
                    label=>"Var1");
$reported->AddField(var=>"var2",
                    label=>"Var2");

is( $x3->GetXML(), "<x xmlns='jabber:x:data'><reported><field label='Var1' var='var1'/><field label='Var2' var='var2'/></reported></x>", "GetXML()");


my $x4 = new Net::Jabber::Stanza("x");
ok( defined($x4), "new()" );
isa_ok( $x4, "Net::Jabber::Stanza" );
isa_ok( $x4, "Net::XMPP::Stanza" );

testScalar($x4, "XMLNS", "jabber:x:data");

my $item = $x4->AddItem();
ok( defined($item), "new()" );
isa_ok( $item, "Net::Jabber::Stanza" );
isa_ok( $item, "Net::XMPP::Stanza" );

ok( defined($x4), "new()" );
isa_ok( $x4, "Net::Jabber::Stanza" );
isa_ok( $x4, "Net::XMPP::Stanza" );

$item->AddField(var=>"var1",
                label=>"Var1");
$item->AddField(var=>"var2",
                label=>"Var2");

is( $x4->GetXML(), "<x xmlns='jabber:x:data'><item><field label='Var1' var='var1'/><field label='Var2' var='var2'/></item></x>", "GetXML()");

my $item2 = $x4->AddItem();
ok( defined($item2), "new()" );
isa_ok( $item2, "Net::Jabber::Stanza" );
isa_ok( $item2, "Net::XMPP::Stanza" );

ok( defined($x4), "new()" );
isa_ok( $x4, "Net::Jabber::Stanza" );
isa_ok( $x4, "Net::XMPP::Stanza" );

$item2->AddField(var=>"var3",
                 label=>"Var3",
                 value=>"value3");
$item2->AddField(var=>"var4",
                 label=>"Var4",
                 value=>"value4");

is( $x4->GetXML(), "<x xmlns='jabber:x:data'><item><field label='Var1' var='var1'/><field label='Var2' var='var2'/></item><item><field label='Var3' var='var3'><value>value3</value></field><field label='Var4' var='var4'><value>value4</value></field></item></x>", "GetXML()");

my @items = $x4->GetItems();
is( $#items, 1, "are there two items?");

is( $items[0]->GetXML(), "<item><field label='Var1' var='var1'/><field label='Var2' var='var2'/></item>", "GetXML()");
is( $items[1]->GetXML(), "<item><field label='Var3' var='var3'><value>value3</value></field><field label='Var4' var='var4'><value>value4</value></field></item>", "GetXML()");

my @fields = $items[1]->GetFields();
is( $#fields, 1, "are there two fields?");

is( $fields[0]->GetXML(), "<field label='Var3' var='var3'><value>value3</value></field>", "GetXML()");
is( $fields[1]->GetXML(), "<field label='Var4' var='var4'><value>value4</value></field>", "GetXML()");

$fields[1]->RemoveValue();

is( $fields[1]->GetXML(), "<field label='Var4' var='var4'/>", "GetXML()");


