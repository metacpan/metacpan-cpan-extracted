
use Net::Jabber qw(Client);
use strict;

if ($#ARGV < 4)
{
    print "\nperl client.pl <server> <port> <username> <password> <resource> \n\n";
    exit(0);
}

my $server = $ARGV[0];
my $port = $ARGV[1];
my $username = $ARGV[2];
my $password = $ARGV[3];
my $resource = $ARGV[4];


$SIG{HUP} = \&Stop;
$SIG{KILL} = \&Stop;
$SIG{TERM} = \&Stop;
$SIG{INT} = \&Stop;

my $Connection = new Net::Jabber::Client();

$Connection->SetXPathCallBacks('/message'=>\&InMessage,
                               '/presence'=>\&InPresence,
                               '/iq'=>\&InIQ);

my $status = $Connection->Connect(hostname=>$server,
                                  port=>$port);

if (!(defined($status)))
{
    print "ERROR:  Jabber server is down or connection was not allowed.\n";
    print "        ($!)\n";
    exit(0);
}

my @result = $Connection->AuthSend(username=>$username,
                                   password=>$password,
                                   resource=>$resource);

if ($result[0] ne "ok")
{
    print "ERROR: Authorization failed: $result[0] - $result[1]\n";
    exit(0);
}

print "Logged in to $server:$port...\n";

$Connection->RosterGet();

print "Getting Roster to tell server to send presence info...\n";

$Connection->PresenceSend();

print "Sending presence to tell world that we are logged in...\n";

while(defined($Connection->Process())) { }

print "ERROR: The connection was killed...\n";

exit(0);


sub Stop
{
    print "Exiting...\n";
    $Connection->Disconnect();
    exit(0);
}


sub InMessage
{
    my $sid = shift;
    my $message = shift;
    
    my $type = $message->GetType();
    my $fromJID = $message->GetFrom("jid");
    
    my $from = $fromJID->GetUserID();
    my $resource = $fromJID->GetResource();
    my $subject = $message->GetSubject();
    my $body = $message->GetBody();
    print "===\n";
    print "Message ($type)\n";
    print "  From: $from ($resource)\n";
    print "  Subject: $subject\n";
    print "  Body: $body\n";
    print "===\n";
    print $message->GetXML(),"\n";
    print "===\n";
}


sub InIQ
{
    my $sid = shift;
    my $iq = shift;
    
    my $from = $iq->GetFrom();
    my $type = $iq->GetType();
    my $query = $iq->GetQuery();
    my $xmlns = $query->GetXMLNS();
    print "===\n";
    print "IQ\n";
    print "  From $from\n";
    print "  Type: $type\n";
    print "  XMLNS: $xmlns";
    print "===\n";
    print $iq->GetXML(),"\n";
    print "===\n";
}

sub InPresence
{
    my $sid = shift;
    my $presence = shift;
    
    my $from = $presence->GetFrom();
    my $type = $presence->GetType();
    my $status = $presence->GetStatus();
    print "===\n";
    print "Presence\n";
    print "  From $from\n";
    print "  Type: $type\n";
    print "  Status: $status\n";
    print "===\n";
    print $presence->GetXML(),"\n";
    print "===\n";
}

