#!/usr/bin/perl

use strict;
use warnings;

use Net::MSN;
use IO::Select;
use POSIX;

use Data::Dumper;

my $handle = 'you@boxen.net';
my $password = 'yourpass';

my $D = 0;
my $PIDFile = './msn-client.pid';
my $LogFile = './msn-client.log';
my $timeout = 0.01;
my $s;


my %admin = (
  'admin@hotmail.com' => 1
);

if (defined $ARGV[0]) {
  if ($ARGV[0] =~ /\-v/i) {
    print "Net::MSN Version: ". $Net::MSN::VERSION. "\n";
    exit;
  } elsif ($ARGV[0] =~ /\-d/i) {
    $D = 1;
  }
}

if ($D == 1) {
  &demonize_me();
} else {
  $s = IO::Select->new();
  $s->add(\*STDIN);
}

my $client = new Net::MSN(
  Debug           =>  1,
  Debug_Lvl       =>  3,
  Debug_STDERR    =>  1,
  Debug_LogCaller =>  1,
  Debug_LogTime   =>  1,
  Debug_LogLvl    =>  1,
  Debug_Log       =>  $LogFile
);

$client->set_event(
  on_connect => \&on_connect,
  on_status  => \&on_status,
  on_answer  => \&on_answer,
  on_message => \&on_message,
  on_join    => \&on_join,
  on_bye     => \&on_bye,
  auth_add   => \&auth_add
);

$client->connect($handle, $password);

while (1) {
  $client->check_event();
  &checkSTDIN() unless ($D == 1);
}

sub checkSTDIN {
  if (my @r = $s->can_read($timeout)) {
    foreach my $fh (@r) {
      my $input = <$fh>;
      print '> '. $input;
      chomp($input);
      
      my ($cmd, @data) = split(/ /, $input);

      next unless (defined $cmd && $cmd);

      if ($cmd eq 'call') {
	if (defined $data[0]) {
	  unless ($client->call($data[0])) {
	    print $data[0]. " is not online or not on your contact list\n";
	  }
	} else {
	  print "no party specified to call!\n";
	}
      } elsif ($cmd eq 'msg') {
	my $calling = shift @data;
	my $message = join(' ', @data);
	my $r = $client->sendmsg($calling, $message);
	print $calling. " is not online or not on your contact list\n"
	  unless (defined $r && $r);
      } elsif ($cmd eq 'list') {
	$client->send('LST', 'RL');
      } elsif ($cmd eq 'quit') {
	$client->disconnect();
	exit;
      } elsif ($cmd eq 'ping') {
	$client->sendnotrid('PNG');
      }	elsif ($cmd eq 'who') {
	my $calling = shift @data;
	my $response = &who();
	$client->sendmsg($calling, $response);
      } elsif ($cmd =~ /die/) {
	die;
      } elsif ($cmd eq 'send') {
	my ($command, @payload) = @data;
	my $payload = '';
	if (@payload && @payload >= 1) {
	  $payload =  join(' ', @payload);
	}
	print STDERR "SEND: ". $command. ' '. $payload. "\n";
	$client->send($command, $payload);
      } elsif ($cmd eq 'dump') {
	use Data::Dumper;
	print '$client = '. Dumper($client). "\n";
      }
    }
  }
}

sub on_connect {
  $client->{_Log}("Connected to MSN @ ". $client->{_Host}. ':'. 
    $client->{Port}. ' as: '. $client->{ScreenName}. 
    ' ('. $client->{Handle}. ")", 3);
}

sub on_status {
  # FIXME
}

sub on_message {
  my ($sb, $chandle, $friendly, $message) = @_;

  print $friendly. " says:\n  ". $message. "\n" unless ($D == 1); 
  if ($message =~ /^reply/i) {
    $sb->sendmsg('yes, what would you like?');
  } elsif ($message =~ /^call\s*(.+?)$/i) {
    $client->call($1);
  } elsif ($message =~ /^calc([^\s])*\s*(.+?)$/) {
    my $sum = $2;
    if ($sum =~ /^[0-9 \-\+\*\/\(\)\^]*$/) {
      $sum = '$ans = '. $sum;
      my $ans;
      eval $sum;
      if (my $err = $@) {
        chomp($err);
        $sb->sendmsg('Error: '. $err);
      } else {
        $sb->sendmsg('Result: '. $ans);
      }
    } else {
       $sb->sendmsg('Error: Syntax Invalid');
    }
  } elsif ($message =~ /^who$/i) {
    my $response = &who($chandle);
    $sb->sendmsg($response);
  } elsif ($message =~ /self\s*destruct/) {
    if ($admin{$chandle} == 1) {
      $sb->sendmsg('YAY, Ive been waiting so long!');
      $sb->sendmsg('Self Destruct Sequence Initiated');
      $sb->sendmsg(5);
      sleep 1;
      $sb->sendmsg(4);
      sleep 1;
      $sb->sendmsg(3);
      sleep 1;
      $sb->sendmsg(2);
      sleep 1;
      $sb->sendmsg(1);
      $sb->sendmsg('*BOOM*');
      $client->disconnect();
      sleep 1;
      die "Self Destructed\n";
    } else {
      $sb->sendmsg('Your not my master!');
    }
  } elsif ($message =~ /^msg\s+([^\s]*)\s+(.+?)$/i) {
    unless ($client->sendmsg($1, $chandle. '> '. $2)) {
      $sb->sendmsg($1. 
	' is either not online, or not on my contact list');
    }
  } elsif ($message =~ /help/i) {
    $sb->sendmsg(&help);
  } else {
    $sb->sendmsg('I dont know, what you say?? "'. $message. '"');
  }
}

sub help {
  return "msn-client's Command List\n\n".
    "Standard Commands:\n".
    " reply       - msn-client will send a message to you\n".
    " calc        - calculate an expression, ie 'calc 1 * 9'\n".
    " who         - shows whos online on msn-client's contact list\n".
    " msg msnname - message someone on msn-client's list\n\n".
    "Admin Commands:\n".
    " self destruct - cause msn-client to quit\n";
}

sub on_bye {
  my ($chandle) = @_;

  $client->{_Log}($chandle. " has left the conversation (switch board)", 3);  
}

sub on_join {
  my ($sb, $chandle, $friendly) = @_;

  $client->{_Log}($chandle. " has joined the conversation (switch board)", 3);  
}

sub on_answer {
  my $sb = shift;

  #print "Answer() called with parameters:\n";
  #print "   " . join(", ", @_), "\n";
}

sub auth_add {
  my ($chandle, $friendly) = @_;

  $client->{_Log}('recieved authorisation request to add '. $chandle. ' ('.
    $friendly. ')', 3);

  return 1;
}

sub who {
  my ($requestor) = @_;
  $requestor = $requestor || '';

  return 'Sorry, nobody is online :('
    unless (defined $client->{Buddies} &&
    ref $client->{Buddies} eq 'HASH');

  my $response;
  foreach my $username (keys %{$client->{Buddies}}) {
    next unless ($client->{Buddies}->{$username}->{StatusCode} eq 'NLN');
    #next if ($username eq $requestor);
    $response .= '* '. $username. ' ('. 
      $client->{Buddies}->{$username}->{DisplayName}.
      ') is '. $client->{Buddies}->{$username}->{Status}. "\n";
  }

  chomp($response);

  return (defined $response && $response) ?
     $response : 'Sorry, nobody is online :(';
}

sub demonize_me ($) {
  print "Daemonizing msn-client ...\n";
  defined (my $pid = fork) or die "Can't fork: $!";
  if ($pid) {
    # close parent process.
    exit;
  } else {
    # use the child process
    if (defined $PIDFile){
      die "ERROR: I Died! Another copy of msn-client seems to be running. ".
	"Check ". $PIDFile. "\n" if (&is_running());
      open(PIDFILE,">$PIDFile") or warn "creating $PIDFile: $!\n";
      print PIDFILE "$$\n";
      close PIDFILE;
    }
    POSIX::setsid or die "Can't start a new session: $!";
    open (STDOUT,'>>'. $LogFile)
      or die "ERROR: Redirecting STDOUT to ". $LogFile. ': '. $!;
    open (STDERR,'>>'. $LogFile)
      or die "ERROR: Redirecting STDERR to ". $LogFile. ': '. $!;
    open (STDIN, '</dev/null') 
      or die "ERROR: Redirecting STDIN from /dev/null: $!";
  }
}
                                                                                                                           
sub is_running {
  if (-f $PIDFile) {
    my $pid = `cat $PIDFile`; chomp($pid);
    my @ps = `ps auxw | grep $pid | grep -v grep`;
    return 1 if ($ps[0]);
  }
  return 0;
}

