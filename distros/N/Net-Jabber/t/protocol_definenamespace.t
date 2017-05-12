use lib "t/lib";
use Test::More tests=>70;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $client = new Net::Jabber::Client();
ok( defined($client), "new()" );
isa_ok( $client, "Net::Jabber::Client" );

$client->DefineNamespace(xmlns=>"foo:bar:1",
                         type=>"X",
                         functions=>[{name=>"Data",
                                      get=>"data",
                                      set=>["scalar","data"],
                                      defined=>"data",
                                      hash=>"data"
                                     },
                                     {name=>"Attrib",
                                      get=>"attrib",
                                      set=>["scalar","attrib"],
                                      defined=>"attrib",
                                      hash=>"att"
                                     },
                                     {name=>"ChildFlag",
                                      get=>"childflag",
                                      set=>["flag","childflag"],
                                      defined=>"childflag",
                                      hash=>"child-flag",
                                     },
                                     {
                                      name=>"ChildData",
                                      get=>"childdata",
                                      set=>["scalar","childdata"],
                                      defined=>"childdata",
                                      hash=>"child-data",
                                     },
                                     {
                                      name=>"AttTagAtt",
                                      get=>"atttagatt",
                                      set=>["scalar","atttagatt"],
                                      defined=>"atttagatt",
                                      hash=>"att-tag-att",
                                     },
                                     {name=>"FooBar",
                                      get=>"__netjabber__:master",
                                      set=>["master"]
                                     }
                                    ]
                        );
my $message = new Net::Jabber::Message();
ok( defined($message), "new()");
isa_ok( $message, "Net::Jabber::Message" );

my $x = $message->NewChild("foo:bar:1");
ok( defined($x), "NewChild()");
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testSetScalar($x,"Data","data");
testScalar($x,"Attrib","attrib");
testFlag($x,"ChildFlag");
testScalar($x,"ChildData","data");
testScalar($x,"AttTagAtt","attrib");

is( $message->GetXML(), "<message><x attrib='attrib' xmlns='foo:bar:1'>data<childflag/><childdata>data</childdata><tag att='attrib'/></x></message>", "GetXML()" );

eval {
$client->DefineNamespace(xmlns=>"foo:bar:2",
                         type=>"X",
                         functions=>[{name=>"Data",
                                      get=>"data",
                                      set=>["scalar","data"],
                                      defined=>"data",
                                      hash=>"data"
                                     },
                                     {name=>"Attrib",
                                      get=>"attrib",
                                      set=>["scalar","attrib"],
                                      defined=>"attrib",
                                      hash=>"att"
                                     },
                                     {name=>"ChildFlag",
                                      get=>"childflag",
                                      set=>["flag","childflag"],
                                      defined=>"childflag",
                                      hash=>"child-flag",
                                     },
                                     {
                                      name=>"ChildData",
                                      get=>"childdata",
                                      set=>["scalar","childdata"],
                                      defined=>"childdata",
                                      hash=>"child-data",
                                     },
                                     {
                                      name=>"ChildAdd",
                                      get=>"childadd",
                                      set=>["add","X","__netjabber__:foo:bar"],
                                      add=>["X","__netjabber__:foo:bar","FooBar","childadd"],
                                      defined=>"childdata",
                                      hash=>"child-add",
                                     },
                                     {
                                      name=>"AttTagAtt",
                                      get=>"atttagatt",
                                      set=>["scalar","atttagatt"],
                                      defined=>"atttagatt",
                                      hash=>"att-tag-att",
                                     },
                                     {
                                      name=>"ChildAdds",
                                      get=>["__netjabber__:children:x","__netjabber__:foo:bar"]
                                     },
                                     {name=>"FooBar",
                                      get=>"__netjabber__:master",
                                      set=>["master"]
                                     }
                                    ]
                        );
};
ok( $@ ne "", "croak test" );

$client->DefineNamespace(xmlns=>"foo:bar:3",
                         type=>"X",
                         functions=>[{name=>"Data",
                                      path=>"text()",
                                     },
                                     {name=>"Attrib",
                                      path=>"\@attrib",
                                     },
                                     {name=>"ChildFlag",
                                      type=>"flag",
                                      path=>"childflag",
                                     },
                                     {
                                      name=>"ChildData",
                                      path=>"childdata/text()",
                                     },
                                     {
                                      name=>"AttTagAtt",
                                      path=>"tag/\@att",
                                     },
                                     {name=>"FooBar",
                                      type=>"master",
                                     }
                                    ]
                        );

my $message2 = new Net::Jabber::Message();
ok( defined($message2), "new()");
isa_ok( $message2, "Net::Jabber::Message" );

my $x2 = $message2->NewChild("foo:bar:3");
ok( defined($x2), "NewChild()");
isa_ok( $x2, "Net::Jabber::Stanza" );
isa_ok( $x2, "Net::XMPP::Stanza" );

testSetScalar($x2,"Data","data");
testScalar($x2,"Attrib","attrib");
testFlag($x2,"ChildFlag");
testScalar($x2,"ChildData","data");
testScalar($x2,"AttTagAtt","attrib");

is( $message2->GetXML(), "<message><x attrib='attrib' xmlns='foo:bar:3'>data<childflag/><childdata>data</childdata><tag att='attrib'/></x></message>", "GetXML()" );


$client->DefineNamespace(xmlns=>"foo:bar:4",
                         type=>"X",
                         functions=>[{name=>"Data",
                                      path=>"text()",
                                     },
                                     {name=>"Attrib",
                                      path=>"\@attrib",
                                     },
                                     {name=>"ChildFlag",
                                      type=>"flag",
                                      path=>"childflag",
                                     },
                                     {
                                      name=>"ChildData",
                                      path=>"childdata/text()",
                                     },
                                     {
                                      name=>"AttTagAtt",
                                      path=>"tag/\@att",
                                     },
                                     {
                                      name=>"ChildAdd",
                                      path=>"childadd",
                                      type=>"node",
                                      child=>["X","__netjabber__:foo:bar:4"],
                                      calls=>["Add"]
                                     },
                                     {
                                      name=>"ChildAdds",
                                      type=>"children",
                                      path=>"childadd",
                                      child=>["X","__netjabber__:foo:bar:4"],
                                     },
                                     {name=>"FooBar",
                                      type=>"master",
                                     }
                                    ]
                        );
$client->DefineNamespace(xmlns=>"__netjabber__:foo:bar:4",
                         type=>"X",
                         functions=>[{name=>"Data",
                                      path=>"text()",
                                     },
                                     {name=>"AddedChild",
                                      type=>"master",
                                     }
                                    ]
                        );
my $message3 = new Net::Jabber::Message();
ok( defined($message3), "new()");
isa_ok( $message3, "Net::Jabber::Message" );

my $x3 = $message3->NewChild("foo:bar:4");
ok( defined($x3), "NewChild()");
isa_ok( $x3, "Net::Jabber::Stanza" );
isa_ok( $x3, "Net::XMPP::Stanza" );

testSetScalar($x3,"Data","data");
testScalar($x3,"Attrib","attrib");
testFlag($x3,"ChildFlag");
testScalar($x3,"ChildData","data");
testScalar($x3,"AttTagAtt","attrib");

my $childadd1 = $x3->AddChildAdd();
testSetScalar($childadd1,"Data","data1");

my $childadd2 = $x3->AddChildAdd(data=>"data2");

my @children = $x3->GetChildAdds();
is( $#children, 1, "are there two kids?" );

is( $message3->GetXML(), "<message><x attrib='attrib' xmlns='foo:bar:4'>data<childflag/><childdata>data</childdata><tag att='attrib'/><childadd>data1</childadd><childadd>data2</childadd></x></message>", "GetXML()" );

