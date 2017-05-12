use lib "t/lib";
use Test::More tests=>15;

BEGIN{ use_ok( "Net::XMPP3" ); }

require "t/mytestlib.pl";

my $jid = new Net::XMPP3::JID('host.com/xxx@yyy.com/zzz');
ok( defined($jid), "new()" );
isa_ok( $jid, "Net::XMPP3::JID" );
is( $jid->GetUserID(), '', "GetUserID()" );
is( $jid->GetServer(), 'host.com', "GetServer()" );
is( $jid->GetResource(), 'xxx@yyy.com/zzz', "GetResource()" );
is( $jid->GetJID("full"), 'host.com/xxx@yyy.com/zzz', "GetJID(\"full\")" );
is( $jid->GetJID("base"), 'host.com', "GetJID(\"base\")" );

my $jid2 = new Net::XMPP3::JID('user@host.com/xxx@yyy.com/zzz');
ok( defined($jid2), "new()" );
isa_ok( $jid2, "Net::XMPP3::JID" );
is( $jid2->GetUserID(), 'user', "GetUserID()" );
is( $jid2->GetServer(), 'host.com', "GetServer()" );
is( $jid2->GetResource(), 'xxx@yyy.com/zzz', "GetResource()" );
is( $jid2->GetJID("full"), 'user@host.com/xxx@yyy.com/zzz', "GetJID(\"full\")" );
is( $jid2->GetJID("base"), 'user@host.com', "GetJID(\"base\")" );



