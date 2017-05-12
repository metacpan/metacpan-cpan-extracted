use lib "t/lib";
use Test::More tests=>33;

BEGIN{
    use_ok( "Net::HTTPServer" );
    use_ok( "Net::HTTPServer::Session" );
}

my $server = new Net::HTTPServer(datadir=>"./t/sessions",
                                 sessions=>1,
                                 log=>"t/access.log",
                                );
ok( defined($server), "new()");
isa_ok( $server, "Net::HTTPServer");

my $session = new Net::HTTPServer::Session(server=>$server);
ok( defined($session), "new()");
isa_ok( $session, "Net::HTTPServer::Session");

ok( !$session->Exists("test1"), "!Exists(test1)");
$session->Set("test1","test1");
ok( $session->Exists("test1"), "Exists(test1)");
is( $session->Get("test1"), "test1", "Get(test1)==test1");
isnt( $session->Get("test1"), "test2", "Get(test1)!=test2");

ok( !$session->Exists("test2"), "!Exists(test2)");
$session->Set("test2",["a","b","c"]);
ok( $session->Exists("test2"), "Exists(test2)");
is_deeply( $session->Get("test2"), ["a","b","c"], "Get(test2)==[a,b,c]");
isnt( $session->Get("test2"), "test1", "Get(test2)!=test1");

ok( !$session->Exists("test3"), "!Exists(test3)");
$session->Set("test3","test3");
ok( $session->Exists("test3"), "Exists(test3)");
is( $session->Get("test3"), "test3", "Get(test3)==test3");
$session->Delete("test3");
ok( !$session->Exists("test3"), "!Exists(test3)");

$session->_save();

ok( -f "./t/sessions/".$session->_key(), "Session file exists");

my $session2 = new Net::HTTPServer::Session(key=>$session->_key(),
                                            server=>$server);
ok( defined($session2), "new()");
isa_ok( $session2, "Net::HTTPServer::Session");

ok( $session2->Exists("test1"), "Exists(test1)");
is( $session2->Get("test1"), "test1", "Get(test1)==test1");
isnt( $session2->Get("test1"), "test2", "Get(test1)!=test2");

ok( $session2->Exists("test2"), "Exists(test2)");
is_deeply( $session2->Get("test2"), ["a","b","c"], "Get(test2)==[a,b,c]");
isnt( $session2->Get("test2"), "test1", "Get(test2)!=test1");

ok( !$session->Exists("test3"), "!Exists(test3)");

ok( -f "./t/sessions/".$session->_key(), "Session file exists");
unlink("./t/sessions/".$session->_key());
ok( !(-f "./t/sessions/".$session->_key()), "Session file doesn't exist");

ok( $session2->_valid(), "Is valid?");
$session2->Destroy();
ok( !$session2->_valid(), "Is not valid?");

$session2->_save();

ok( !(-f "./t/sessions/".$session->_key()), "Session file doesn't exist");

