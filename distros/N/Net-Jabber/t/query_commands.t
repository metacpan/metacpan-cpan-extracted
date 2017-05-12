use lib "t/lib";
use Test::More tests=>59;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $query = new Net::Jabber::Stanza("command");
ok( defined($query), "new()" );
isa_ok( $query, "Net::Jabber::Stanza" );
isa_ok( $query, "Net::XMPP::Stanza" );

testScalar($query,"XMLNS","http://jabber.org/protocol/commands");

testScalar($query,"Action","action");
testScalar($query,"Node","node");
testScalar($query,"SessionID","sessionid");
testScalar($query,"Status","status");

is( $query->GetXML(), "<command action='action' node='node' sessionid='sessionid' status='status' xmlns='http://jabber.org/protocol/commands'/>", "GetXML()" );

my $query2 = new Net::Jabber::Stanza("command");
ok( defined($query2), "new()" );
isa_ok( $query2, "Net::Jabber::Stanza" );
isa_ok( $query2, "Net::XMPP::Stanza" );

testScalar($query2,"XMLNS","http://jabber.org/protocol/commands");

$query2->SetCommand(action=>'action',
                    node=>'node',
                    sessionid=>'sessionid',
                    status=>'status'
                   );

testPostScalar($query2,"Action","action");
testPostScalar($query2,"Node","node");
testPostScalar($query2,"SessionID","sessionid");
testPostScalar($query2,"Status","status");

is( $query2->GetXML(), "<command action='action' node='node' sessionid='sessionid' status='status' xmlns='http://jabber.org/protocol/commands'/>", "GetXML()" );


my $query3 = new Net::Jabber::Stanza("command");
ok( defined($query3), "new()" );
isa_ok( $query3, "Net::Jabber::Stanza" );
isa_ok( $query3, "Net::XMPP::Stanza" );

testScalar($query3,"XMLNS","http://jabber.org/protocol/commands");

my $note = $query3->AddNote();
isa_ok( $note, "Net::Jabber::Stanza" );
isa_ok( $note, "Net::XMPP::Stanza" );

testScalar($note,"Type","type1");
testSetScalar($note,"Message","message1");


is( $query3->GetXML(), "<command xmlns='http://jabber.org/protocol/commands'><note type='type1'>message1</note></command>", "GetXML()" );

my $note2 = $query3->AddNote(type=>"type2",
                             message=>"message2"
                            );
isa_ok( $note2, "Net::Jabber::Stanza" );
isa_ok( $note2, "Net::XMPP::Stanza" );

testPostScalar($note2,"Type","type2");
testPostScalar($note2,"Message","message2");


is( $query3->GetXML(), "<command xmlns='http://jabber.org/protocol/commands'><note type='type1'>message1</note><note type='type2'>message2</note></command>", "GetXML()" );

my @notes = $query3->GetNotes();
is($#notes,1,"two items");

is( $notes[0]->GetXML(), "<note type='type1'>message1</note>","note 1 - GetXML()");
is( $notes[1]->GetXML(), "<note type='type2'>message2</note>","note 2 - GetXML()");


