use lib "t/lib";
use Test::More tests=>15;

BEGIN{ use_ok( "Net::XMPP" ); }

require "t/mytestlib.pl";

my $jid = Net::XMPP::JID->new('host.com/xxx@yyy.com/zzz');
ok( defined($jid), "new()" );
isa_ok( $jid, "Net::XMPP::JID" );
is( $jid->GetUserID(), '', "GetUserID()" );
is( $jid->GetServer(), 'host.com', "GetServer()" );
is( $jid->GetResource(), 'xxx@yyy.com/zzz', "GetResource()" );
is( $jid->GetJID("full"), 'host.com/xxx@yyy.com/zzz', "GetJID(\"full\")" );
is( $jid->GetJID("base"), 'host.com', "GetJID(\"base\")" );

my $jid2 = Net::XMPP::JID->new('user@host.com/xxx@yyy.com/zzz');
ok( defined($jid2), "new()" );
isa_ok( $jid2, "Net::XMPP::JID" );
is( $jid2->GetUserID(), 'user', "GetUserID()" );
is( $jid2->GetServer(), 'host.com', "GetServer()" );
is( $jid2->GetResource(), 'xxx@yyy.com/zzz', "GetResource()" );
is( $jid2->GetJID("full"), 'user@host.com/xxx@yyy.com/zzz', "GetJID(\"full\")" );
is( $jid2->GetJID("base"), 'user@host.com', "GetJID(\"base\")" );



