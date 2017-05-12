use strict;
use Test::More tests => 22;

BEGIN{ use_ok('Net::SCP::Expect') }

my $scp = Net::SCP::Expect->new(
   user     => "some_user",
   host     => "ssh.rubynet.org",
   password => "blah",
);

is("ssh.rubynet.org",$scp->_get("host"),"host attribute");
is("some_user",$scp->_get("user"),"user attribute");
is("blah",$scp->_get("password"),"password attribute");
is(undef,$scp->_get("cipher"),"cipher attribute");
is(undef,$scp->_get("port"),"port attribute");
is(undef,$scp->_get("error_handler"),"error_handler attribute");
is(0,$scp->_get("preserve"),"preserve attribute");
is(0,$scp->_get("recursive"),"recursive attribute");
is(0,$scp->_get("verbose"),"verbose attribute");
is(0,$scp->_get("auto_yes"),"auto_yes attribute");
is(10,$scp->_get("timeout"),"timeout attribute");
is(1,$scp->_get("timeout_auto"),"timeout_auto attribute");
is(undef,$scp->_get("timeout_err"),"timeout_err attribute");
is(0,$scp->_get("no_check"),"no_check attribute");
is(undef,$scp->_get("protocol"),"protocol");
is("\n",$scp->_get("terminator"),"terminator");
is(undef,$scp->_get("subsystem"),"subsystem attribute");
is(undef,$scp->_get("option"),"option attribute");
is(undef,$scp->_get("identity_file"),"identity_file attribute");
is(1,$scp->_get("auto_quote"),"auto_quote attribute");
is(undef,$scp->_get("scp_path"),"scp_path attribute");
