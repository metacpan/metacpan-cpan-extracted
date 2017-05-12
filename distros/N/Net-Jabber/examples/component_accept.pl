
use Net::Jabber qw(Component);
use strict;

if ($#ARGV < 2) {
  print "\nperl component_accept.pl <server> <port> <name> <secret> \n\n";
  exit(0);
}

my $server = $ARGV[0];
my $port = $ARGV[1];
my $name = $ARGV[2];
my $secret = $ARGV[3];

$SIG{HUP} = \&Stop;
$SIG{KILL} = \&Stop;
$SIG{TERM} = \&Stop;
$SIG{INT} = \&Stop;

my $Component = new Net::Jabber::Component();

$Component->SetCallBacks(onauth=>\&onAuth,
                         message=>\&messageCB);

$Component->Execute(hostname=>$server,
                    port=>$port,
                    componentname=>$name,
                    secret=>$secret
                   );

sub onAuth
{
    print "Connected...\n";
}

sub Stop
{
  $Component->Disconnect();
  print "Exit gracefully...\n";
  exit(0);
}


sub messageCB
{
  my $sid = shift;
  my $message = shift;

  print "Recd: ",$message->GetXML(),"\n";

  my $reply = $message->Reply();
  $reply->SetMessage(body=>uc($message->GetBody()));
  $Component->Send($reply);

  print "Sent: ",$reply->GetXML(),"\n";
}
