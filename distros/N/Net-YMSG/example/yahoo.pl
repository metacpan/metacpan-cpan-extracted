#!perl
use Net::YMSG;
use strict;

my $chatroom="Linux, FreeBSD, Solaris:1";
my $chatroomcode="1600326591";

my $yahoo;
my ($yahoo_id, $password);
$SIG{ALRM} = sub {
	 $yahoo->do_one_loop;
	 alarm 1;
};

while (1) {
	 $yahoo_id = get_yahoo_id() unless $yahoo_id;
	 $password = get_password($yahoo_id);

	 $yahoo = Net::YMSG->new(
			   id                => $yahoo_id,
			   password          => $password,
			   hostname      => 'scs.yahoo.com',
							);
	 $yahoo->set_event_handler(new CommandLineEventHandler);

	 print "\n";
	 print "Connecting to Yahoo! as $yahoo_id\n";
	 $yahoo->login and last;
#$yahoo->invisible;
#alarm 1;
	 print STDERR "[system] Invalid Login\n";
	 print STDERR "Make sure your ID and PASSWORD are entered correctly.\n";
}
my %nametonum;
my %numtoname;
my %ignorehash;
my $count=1;
$|++;
my $to;
my $chatflag=0;
$yahoo->add_event_source(\*STDIN, sub {
		  my $message = scalar <STDIN>;
		  chomp $message;
#print "[debug]message:$message.\n";
		  if ($message =~ m{^/id\s+(.+)$}) {
		  $to = $1;
		  if( ! defined $nametonum{"$to"} ) {
		  $nametonum{"$to"} = $count;
		  $numtoname{"$count"}=$to;
		  $count++;
		  }
		  }
		  elsif ($message =~ m{^!\s+(.+)$}) {
		  my @cmdarr=`$1`;
		  print join "\n",@cmdarr;
		  }
		  elsif ($message =~ m{^/st\s+(.+)$}) {
		  $yahoo->change_state(0, $1);
		  }
		  elsif ($message =~ m{^/j$}) {
		  my $msg = $yahoo->pre_join();
		  my $msg=$yahoo->join_room($chatroom,$chatroomcode);
		  $chatflag=1;
#printf "sending %s\n",$msg;
		  }

		  elsif ($message =~ m{^/ig\s+(.+)$}) {
			   $ignorehash{"$1"}=1;
		  }
		  elsif ($message =~ m{^/inv$}) {
			   $yahoo->invisible();
		  }

		  elsif ($message =~ m{^/q$}) {
			   exit;
		  }
		  elsif ($message =~ m{^/m}) {
			   my $y;
			   foreach $y (keys %numtoname) {
					print $numtoname{"$y"}." = ".$y."\n";
			   }
		  }
		  elsif ($message =~ m{^/o$}) {
			   my $users = join "\n", map {
					$_->to_string
			   } grep { $_->is_online } $yahoo->buddy_list;
			   print $users, "\n";
		  }
		  elsif ($message =~ m{^/l$}) {
			   $yahoo->logoffchat;
			   $chatflag=0;
#$yahoo->logoffchat;
		  }

		  elsif ($message =~ /\/r\s+/) {
			   my @arr = split(/\s+/,$message);
			   my $num = substr $arr[0],1;
#$to=$numtoname{"$num"};
			   shift @arr;
			   my $messagetosend = join ' ',@arr;

			   $yahoo->chatsend($chatroom,$messagetosend);
			   print "<".$yahoo_id.">".$messagetosend."\n";
		  }


		  elsif($message =~ /^\/\d+\s/) {
			   my @arr = split(/\s+/,$message);
			   my $num = substr $arr[0],1;
			   $to=$numtoname{"$num"};
			   shift @arr;
			   my $messagetosend = join ' ',@arr;
			   if($messagetosend eq "") {
					$messagetosend="<ding>";
			   }
			   $yahoo->send($to, $messagetosend);
#print "[sendingmessage] to $num $to $messagetosend\n";
			   printf "[03;32m[$yahoo_id(".$to."-".$nametonum{"$to"}.")][06;36m %s [0m \n", $messagetosend;
		  }
		  elsif ($message =~ m{^/h$}) {
			   print <<__USAGE__;
Usage:
/id : set TO_YAHOO_ID
/inv : become invisible
/j   : join yahoo chat
/l   : log off chat
/ig {yahoo_id} : ignore user
/st : STATUS
/b : Online Buddies
/o : Online buddies
/m : Buddy number map
/{number} {message} : message to buddy number
{message} : goes to the buddy set by last /id or in the chat room if logged in
! {command} : execute a shell command
/h : Help
/q : QUIT

__USAGE__

		  }
		  elsif ($message ne '') {
			   if($chatflag != 1) {
					if($message eq "") {
						 $message="<ding>";
					}
					$yahoo->send($to, $message);
					if( ! defined $nametonum{"$to"} ) {
						 $nametonum{"$to"} = $count;
						 $numtoname{"$count"}=$to;
						 $count++;
					}

					printf "[03;32m [$yahoo_id(".$to."-".$nametonum{"$to"}.")][06;36m %s [0m\n", $message;
			   } 
			   else {
					$yahoo->chatsend($chatroom,$message);
					print "<".$yahoo_id.">".$message."\n";

			   }
		  }
}, 'r');
$yahoo->start;
exit;

sub get_yahoo_id
{
	 my $yahoo_id;
	 while (1) {
		  print "Yahoo ID: ";
		  chomp($yahoo_id = <STDIN>);
		  return $yahoo_id if $yahoo_id ne '';
	 }
}

sub get_password
{
	 my $yahoo_id = shift;
	 my $password;
	 while (1) {
		  system 'stty -echo';
		  print "Password[$yahoo_id]: ";
		  chomp($password = <STDIN>);
		  system 'stty echo';
		  print "\n";
		  return $password if $password ne '';
	 }
}


package CommandLineEventHandler;
use base 'Net::YMSG::EventHandler';
use strict;

use constant STATUS_MESSAGE => [
"I'm Available",
'Be Right Back',
'Busy',
'Not At Home',
'Not At My Desk',
'Not In The Office',
'On The Phone',
'On Vacation',
'Out To Lunch',
'Stepped Out',
];

my $first=0;
sub UnImplementEvent
{
	 my $self = shift;
	 my $event = shift;
}

sub ChatRoomLogoff
{
	 my $self = shift;
	 my $event = shift;
	 print "Left the room : ".$event->from;
	 print "\n";
}

sub ChatRoomLogon
{
	 my $self = shift;
	 my $event = shift;
	 print "Joined the room : ".$event->from;
	 print "\n";
}
sub ChatRoomReceive
{
	 my $self = shift;
	 my $event = shift;
	 my $from = $event->from;
	 if(! defined $ignorehash{"$from"}) {
		  my $body = $event->body;
		  $body =~ s{</?(?:font|FACE).+?>}{}g;
		  print "[06;32m (".$event->from.")[06;36m : ".$body."[0m \n";
	 }
}



sub Login
{
	 my $self = shift;
	 my $event = shift;
	 my $yahoo = $event->get_connection;

	 printf "[06;31m[system] Friends for - %s[0m \n", $event->from;

	 my $baddy_status = join "\n", map {
		  $_->to_string
	 } $yahoo->buddy_list;
	 print $baddy_status, "\n";
}


sub GoesOnline
{
	 my $self = shift;
	 my $event = shift;
	 my $from = $event->from;
	 if( ! defined $nametonum{"$from"} ) {
		  $nametonum{"$from"} = $count;
		  $numtoname{"$count"}=$from;
		  $count++;
	 }

	 printf "[05;31m[system] %s(%s) goes in.[0m \n", $event->from,$nametonum{"$from"};
}


sub GoesOffline
{
	 my $self = shift;
	 my $event = shift;

	 if ($event->from) {
		  print "[06;31m[system]".$event->from."goes out.[0m \n";
	 } else {
		  print "[05;31m[system] You have been logged off as you have logged in on a different machine.[00;00m \n";
		  exit;

	 }
}

sub ChangeState
{
	 my $self = shift;
	 my $event = shift;

	 my $busy_status = $event->busy == 1 ?
		  '(Busy) ' :
		  $event->busy == 2 ?
		  '(Sleep) ' : '';

	 my $message;
	 if ($event->status_code == 99) {
		  $message = sprintf "[%s] %sTransit to '%s'\n",
		  $event->from, $busy_status, $event->body;
	 }
	 else {
		  $message = sprintf "[%s] %sTransit to '%s'\n",
		  $event->from, $busy_status, STATUS_MESSAGE->[$event->status_code]; 
	 }
	 print $message;
}


sub NewFriendAlert
{
	 my $self = shift;
	 my $event = shift;

	 my $message = sprintf "[05;31m [system] New Friend Alert: %s added %s as a Friend.\n",
	 $event->from, $event->to;
	 $message .= sprintf "and also sent the following message: %s[06;36m\n",
	 $event->body; 
	 print $message."[0m";
}

sub ReceiveMessage
{
	 my $self = shift;
	 my $event = shift;
	 my @from = split("\x80",$event->from);
	 my @body = split("\x80",$event->body);
	 my $i;
	 if($first==0 && $#from >= 1) {
#might be offline messages 
		  print "[05;31mYour Offline messages :\n[They have been saved in the file \'offline\' in the current directory]\n[0m";
		  open(OFFLINE,">>offline") || printf "Error opening file offline";
		  for($i=0;$i<=$#from;$i++) {
			   print OFFLINE "[".$from[$i]."]: ".$body[$i]."\n";
		  }
		  close(OFFLINE);
	 }
	 $first=1;
# print "body$body from $from\n";
	 for($i=0;$i<=$#from;$i++) {
		  if ($body[$i] ne "") {
			   $body[$i] =~ s{</?(?:font|FACE).+?>}{}g;
			   if( ! defined $nametonum{"$from[$i]"} ) {
					$nametonum{"$from[$i]"} = $count;
					$numtoname{"$count"}=$from[$i];
					$count++;
			   }

			   my $message = sprintf "[06;32m;[%s(%s)][06;36m %s [0m\n", $from[$i],$nametonum{"$from[$i]"},$body[$i];
			   print $message."[0m";
		  }
	 }

}

1;
__END__


