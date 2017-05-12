# -*- perl -*-
#
# $Id: client.t,v 1.3 1999/01/29 20:15:47 joe Exp $
#

require IO::Socket;
require Net::Nessus::Client;



my $testNum = 0;
sub Test {
    my $result = shift; my $msg = shift;
    $msg = $msg ? " $msg" : "";
    ++$testNum;
    if ($result) {
	print "ok $testNum$msg\n";
    } else {
	print "not ok $testNum$msg\n";
    }
    $result;
}


# Check whether the Nessus Server is alive
my $cfg = require ".status";
my($host, $port) = ($cfg->{'nessus_host'}, $cfg->{'nessus_port'});
my $sock = IO::Socket::INET->new('PeerAddr' => $host,
				 'PeerPort' => $port,
				 'Proto' => 'tcp');
if (!$sock) {
    print STDERR ("Cannot connect to the Nessus server at host $host,",
		  " port $port.\n");
    print STDERR ("Please check, whether the server is running and the",
		  " above settings are correct.\n");
    print "1..0\n";
    exit 0;
}
undef $sock;
print "1..31\n";


my $client;
print "Requesting an impossible protocol version.\n";
Test(!($client = eval{ Net::Nessus::Client->new
			   ('host' => $host,
			    'port' => $port,
			    'user' => $cfg->{'nessus_user'},
			    'password' => $cfg->{'nessus_password'},
			    'ntp_proto' => '99999999.9'
			   )})  and  $@ =~ /NTP proto/);

print "Requesting protocol version 1.0\n";
Test($client = eval { Net::Nessus::Client->new
			  ('host' => $host,
			   'port' => $port,
			   'user' => $cfg->{'nessus_user'},
			   'password' => $cfg->{'nessus_password'},
			   'ntp_proto' => '1.0'
			  )});
Test($client->Plugins());
Test(!$client->Prefs());
Test(!$client->Rules());

foreach my $proto ('1.1', '1.2') {
    print "Requesting protocol version $proto\n";
    Test(($client = eval { Net::Nessus::Client->new
			       ('host' => $host,
				'port' => $port,
				'user' => $cfg->{'nessus_user'},
				'password' => $cfg->{'nessus_password'},
				'ntp_proto' => $proto,
#			        'Dump_Log' => 'dump.log'
			       )})  or
	 $@ =~ /NTP proto/);

    if ($client) {
	Test($client->Plugins());
	Test($client->Prefs());
	Test($client->Rules());

	my $msg = Net::Nessus::Message::RULES->new(["n:*;", "y:*.nain.org"]);
	Test($msg);
	Test($msg->{'lines'}->[0] eq "n:*;");
	Test($msg->{'lines'}->[1] eq "y:*.nain.org");
	eval { $client->Print($msg) };
	Test(!$@) or print "$@\n";

	$msg = Net::Nessus::Message::PREFERENCES->new({});
	Test($msg);
	Test(keys(%{$msg->Prefs()}) == 0);
	eval { $client->Print($msg) };
	Test(!$@) or print "$@\n";
	$msg = $client->GetMsg('PREFERENCES_ERRORS');
	Test($msg);
	Test(keys(%{$msg->Prefs()}) == 0);
    } else {
	for (my $i = 0;  $i < 12;  $i++) {
	    Test(1, "# Skip");
	}
    }
}
