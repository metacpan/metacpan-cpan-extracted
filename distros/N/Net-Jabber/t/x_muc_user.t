use lib "t/lib";
use Test::More tests=>129;

BEGIN{ use_ok( "Net::Jabber" ); }

require "t/mytestlib.pl";

my $x = new Net::Jabber::Stanza("x");
ok( defined($x), "new()" );
isa_ok( $x, "Net::Jabber::Stanza" );
isa_ok( $x, "Net::XMPP::Stanza" );

testScalar($x,"XMLNS",'http://jabber.org/protocol/muc#user');

testScalar($x,"Alt","alt");
testScalar($x,"Password","password");
testScalar($x,"StatusCode","code");

is( $x->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/></x>", "GetXML()");

my $invite = $x->AddInvite();

is( $x->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/><invite/></x>", "GetXML()");

testJID($invite,"From","user1", "server1", "resource1");
testJID($invite,"To","user2", "server2", "resource2");
testScalar($invite,"Reason","reason");

is( $x->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/><invite from='user1\@server1/resource1' to='user2\@server2/resource2'><reason>reason</reason></invite></x>", "GetXML()");

my $item = $x->AddItem();

is( $x->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/><invite from='user1\@server1/resource1' to='user2\@server2/resource2'><reason>reason</reason></invite><item/></x>", "GetXML()");

testJID($item,"ActorJID","user3", "server3", "resource3");
testScalar($item,"Affiliation","affiliation");
testJID($item,"JID","user4", "server4", "resource4");
testScalar($item,"Nick","nick");
testScalar($item,"Reason","reason");
testScalar($item,"Role","role");

is( $x->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/><invite from='user1\@server1/resource1' to='user2\@server2/resource2'><reason>reason</reason></invite><item affiliation='affiliation' jid='user4\@server4/resource4' nick='nick' role='role'><actor jid='user3\@server3/resource3'/><reason>reason</reason></item></x>", "GetXML()");

my $x2 = new Net::Jabber::Stanza("x");
ok( defined($x2), "new()" );
isa_ok( $x2, "Net::Jabber::Stanza" );
isa_ok( $x2, "Net::XMPP::Stanza" );

testScalar($x2,"XMLNS","http://jabber.org/protocol/muc#user");

$x2->SetUser(alt=>"alt",
             password=>"password",
             statuscode=>"code"
            );

testPostScalar($x2,"Alt","alt");
testPostScalar($x2,"Password","password");
testPostScalar($x2,"StatusCode","code");

is( $x2->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/></x>", "GetXML()");

my $invite2 = $x2->AddInvite(from=>'user5@server5/resource5',
                             reason=>"reason",
                             to=>'user6@server6/resource6');

testPostJID($invite2,"From","user5", "server5", "resource5");
testPostJID($invite2,"To","user6", "server6", "resource6");
testPostScalar($invite2,"Reason","reason");

is( $x2->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/><invite from='user5\@server5/resource5' to='user6\@server6/resource6'><reason>reason</reason></invite></x>", "GetXML()");

my $item2 = $x2->AddItem(actorjid=>'user7@server7/resource7',
                         affiliation=>"affiliation",
                         jid=>'user8@server8/resource8',
                         nick=>"nick",
                         reason=>"reason",
                         role=>"role");
             
testPostJID($item2,"ActorJID","user7", "server7", "resource7");
testPostScalar($item2,"Affiliation","affiliation");
testPostJID($item2,"JID","user8", "server8", "resource8");
testPostScalar($item2,"Nick","nick");
testPostScalar($item2,"Reason","reason");
testPostScalar($item2,"Role","role");

is( $x2->GetXML(), "<x xmlns='http://jabber.org/protocol/muc#user'><alt>alt</alt><password>password</password><status code='code'/><invite from='user5\@server5/resource5' to='user6\@server6/resource6'><reason>reason</reason></invite><item affiliation='affiliation' jid='user8\@server8/resource8' nick='nick' role='role'><actor jid='user7\@server7/resource7'/><reason>reason</reason></item></x>", "GetXML()");

