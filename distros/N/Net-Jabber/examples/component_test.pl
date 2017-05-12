
use Net::Jabber qw(Client);
use strict;

if ($#ARGV < 5) {
  print "\nperl client.pl <server> <port> <username> <password> <resource>\n";
  print "                 <componentname>\n\n"
;
  exit(0);
}

my $server = $ARGV[0];
my $port = $ARGV[1];
my $username = $ARGV[2];
my $password = $ARGV[3];
my $resource = $ARGV[4];
my $component = $ARGV[5];

my $Client = new Net::Jabber::Client;

$Client->SetCallBacks(message=>\&messageCB);

my $status = $Client->Connect(hostname=>$server,
			      port=>$port);

if (!(defined($status))) {
  print "ERROR:  Jabber server $server is not answering.\n";
  print "        ($!)\n";
  exit(0);
}

print "Connected...\n";

my @result = $Client->AuthSend(username=>$username,
			       password=>$password,
			       resource=>$resource);

if ($result[0] ne "ok") {
  print "ERROR: $result[0] $result[1]\n";
}

print "Logged in...\n";

$Client->MessageSend(to=>$component,
		     body=>"this is a test... a successful test...");

$Client->Process();

$Client->Disconnect();


sub messageCB {
  my $sid = shift;
  my $message = shift;

  print "The body of the message should read:\n";
  print "  (THIS IS A TEST... A SUCCESSFUL TEST...)\n";
  print "\n";
  print "Recvd: ",$message->GetBody(),"\n";
}
