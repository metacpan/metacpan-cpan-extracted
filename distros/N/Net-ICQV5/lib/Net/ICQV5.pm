package Net::ICQV5;

=head1 NAME

C<Net::ICQV5> - Net::ICQV5 is a Perl module that allows your Perl programs 
to send and receive ICQ messages.

=head1 SYNOPSIS

 use Net::ICQV5CD;
 $ICQ = new Net::ICQV5 ('icq4.mirabilis.com','4000');
 $ICQ->login($uin,$password) || die "Couldn't log on.";
 $ICQ->logout();

=head1 DESCRIPTION

Net::ICQV5 is a Perl module that allows your Perl programs to send and receive 
ICQ messages. Perhaps the most obvious use of Net::ICQ would be to write an ICQ 
client in Perl. Some other uses that people have come up with are: 

Allow a server or daemon to notify its administrator via ICQ when a critical 
error occurrs.
Enable ICQ chat functionality where youd never thought of it before: MUDs, 
IRC bots, etc. 

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

use Data::Dumper;
use IO::Socket;
use IO::Select;
use Sys::Hostname;
use Symbol;
use Fcntl;
use Net::ICQV5CD;

use Carp;                      # Regular Carp
#use Carp qw(verbose);         # This one's for debugging - uses line numbers

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

$VERSION = "1.20";

##############################################################################

my $ICQ_Version  = 5;
my $Default_ICQ_Port = 4000;
my $Default_ICQ_Host = "icq4.mirabilis.com";

my $scriptname = "Net::ICQV5 by Sergei A. Nemarov / v$VERSION";

my $DEBUG = 1;

my $pkgnum=1;
my @rndletters = ("q","w","e","r","t","y","u","i","o","p","a","s","d","f","g","h","j","k","l","z","x","c","v","b","n","m");

my $logfile = "Net::ICQV5.log";
my $logfileison = 1;
my $logstringison = 0;

my $allowoutput = 1;

my $separator = "-------------------------------------------------------------------------------";
##############################################################################
my %color =(
    'normal'     => "[0;37m",
    'black'      => "[0;30m",
    'red'        => "[0;31m" ,
    'ligthred'   => "[1;31m",
    'green'      => "[0;32m",
    'ligthgreen' => "[1;32m",
    'blue'       => "[0;34m",
    'ligthblue'  => "[1;34m",
    'white'      => "[0;38m",
    'yelow'      => "[1;33m" ,
    '0' => "[0;30m",
    '1' => "[0;31m",
    '2' => "[0;32m",
    '3' => "[0;33m",
    '4' => "[0;34m",
    '5' => "[0;35m",
    '6' => "[0;36m",
    '7' => "[0;37m",
    '8' => "[0;38m",
    '9' => "[0;39m",
    'sim' => "[5m",
);
##############################################################################
my %user_status = (
    "STATUS_OFFLINE"  => 0xFFFF,
    "STATUS_ONLINE"   => 0x0000,
    "STATUS_AWAY"     => 0x0001,
    "STATUS_DND"      => 0x0002,
    "STATUS_NA_99"    => 0x0005,
    "STATUS_NA"       => 0x0004,
    "STATUS_OCCUPIED" => 0x0010,
    "STATUS_OCCUPIED_MAC" => 0x0011,
    "STATUS_DND_KXICQ" => 0x0013,
    "STATUS_FFC"       => 0x0020,
    "STATUS_DND_99"    => 0x0022,
    "STATUS_INVISIBLE" => 0x0100,
    "STATUS_UNKNOWN"   => 0xFFFE,
);
my %user_status_bynumber = reverse %user_status;
##############################################################################
my %message_types = (
    "TCP_START"  =>      0x07EE,
    "TCP_CANCEL" =>      0x07D0,
    "TCP_ACK"    =>      0x07DA,
    "TCP_MSG"    =>      0x0001,
    "TCP_FILE"   =>      0x0003,
    "TCP_CHAT"   =>      0x0002,
    "TCP_URL"    =>      0x0004,
    "TCP_ADDED"  =>      0x000C,
    );
my %message_types_by_bynumber = reverse %message_types;
##############################################################################
my %server_commands = (
    "S_ACK" =>               0x000A,   #   /* Ack */
    "S_SEARCH_ERROR" =>	     0x001E,   #   /* search error, server error ?? */
    "S_SILENT_TOO_LONG" =>   0x0028,   #
    "S_NEW_USER_UIN" =>      0x0046,   #   /* Confirmation of new user with UIN */
    "S_REG_DENY" =>          0x0050,   #   
    "S_LOGIN_REPLY"  =>      0x005A,   #   /* Login reply */
    "S_WRONG_PASSWORD" =>    0x0064,
    "S_USER_ONLINE"  =>      0x006E,   #   /* user in clist changed status */
    "S_USER_OFFLINE" =>      0x0078,   #   /* user in clist has gone offline */
    "S_QUERY_REPLY" =>       0x0082,   #   /* Response to QUERY_SERVERS or QUERY_A*/
    "S_USER_FOUND"   =>      0x008C,   #   /* user record found matching query */
    "S_END_OF_SEARCH" =>     0x00A0,   #   /* No more USER_FOUND will be sent */
    "S_NEW_USER_REPLY" =>    0x00B4,   #   /* Confirmation of new user info */
    "S_UPDATE_EXT_REPLY" =>  0x00C8,   #   /* Confirmation of extended update */
    "S_RECEIVE_MESSAGE" =>   0x00DC,   #   /* message sent while offline */
    "S_SYSMESSAGE_DONE" =>   0x00E6,   #   /* system message are done */
    "S_DISCONNECTED" =>      0x00F0,   #   /* We got disconnected? */
    "S_TRY_AGAIN" =>	     0x00FA,   #   /* try again */
    "S_GET_MESSAGE"   =>     0x0104,   #   /* message from user (sent throu server) */
    "S_INFO_REPLY"  =>       0x0118,   #   /* Return basic information */
    "S_EXT_INFO_REPLY" =>    0x0122,   #   /* Return extended information */
    "S_INVALID_UIN" =>	     0x012C,
    "S_STATUS_UPDATE" =>     0x01A4,   #   /* User on contact list changed stat */
    "S_SYSTEM_MESSAGE" =>    0x01C2,   #   /* System message with URL button */
    "S_UPDATE_REPLY" =>      0x01E0,   #   /* Confirmation of basic update */
    "S_UPDATE_REPLY_FAIL" => 0x01EA,   #   /* Confirmation of basic update fail*/
    "S_MULTI_PACKET" =>	     0x0212,	
    "S_END_CONTACTLIST_STATUS" => 0x021C,
    "S_RAND_USER" =>         0x024E,
    "S_WEB_ACK" =>           0x03DE,
    "S_WRONG_PASSWORD_2" =>  0x8300,
);
my %server_commands_bynumber = reverse %server_commands;
##############################################################################
my %client_commands = (
    "C_ACK" =>               0x000A,     # /* acknowledgement */
    "C_ACK_MSG" =>           0x0442,	 # /* Ack message (delete from server) */
    "C_SEND_MESSAGE" =>      0x010E,     # /* send message to offline user */
    "C_LOGIN" =>             0x03E8,     # /* login on server */
    "C_CONTACT_LIST" =>      0x0406,     # /* Inform the server of cont. list */
    "C_SEARCH_UIN" =>        0x041A,     # /* search for user by UIN */
    "C_SEARCH_USER" =>       0x0424,     # /* search for user by name/email */
    "C_KEEP_ALIVE" =>        0x042E,     # /* keep alive */
    "C_KEEP_ALIVE_2" =>      0x051e,     # /* keep alive 2 */
    "C_SEND_TEXT_CODE" =>    0x0438,     # /* send special message to server */
    "C_LOGIN_1" =>           0x044C,     # /* request system messages */
    "C_INFO_REQ" =>          0x0460,     # /* Request basic information */
    "C_EXT_INFO_REQ" =>      0x046A,     # /* Request extended information */
    "C_CHANGE_PASSWORD" =>   0x049C,     # /* Change the user's password */
    "C_STATUS_CHANGE" =>     0x04D8,     # /* Change status of user (Away etc.) */
    "C_LOGIN_2" =>           0x0528,     # /* Sent during Login */
    "C_UPDATE_INFO" =>       0x050A,     # /* Update my basic information */
    "C_UPDATE_EXT_INFO" =>   0x04B0,     # /* Update my extended information */
    "C_ADD_TO_LIST" =>       0x053C,     # /* Add user to contact list (clist)*/
    "C_REQ_ADD_TO_LIST" =>   0x0456,     # /* Request auth to add to clist */
    "C_QUERY_STATUS" =>      0x04BA,     # /* Query about other servers */
    "C_QUERY_ADDONS" =>      0x04C4,     # /* Query about global add-ons */
    "C_NEW_USER_1" =>        0x04EC,     # /* Ask for permission to add new usr */
    "C_NEW_USER_REG" =>      0x03FC,     # /* Register a new user */
    "C_MSG_TO_NEW_USER" =>   0x0456,     # /* Send a message to not in clist */
    "C_META_USER" =>         0x064A,
    "C_WEB_FINISCH" =>       0x04D8,
    "C_VISIBLE_LIST" =>	     0x06AE,	 #		/* send visible list */
    "C_INVISIBLE_LIST" =>    0x06A4,	 #		/* send invisible list */
    "C_SYSMESSAGE_ACK" =>    0x0442,
    "C_RAND_SEARCH" =>       0x056E,                                                                                                                                
    "C_RAND_SET" =>          0x0564, 
    "C_INVISIBLE_STATUS" =>  0x06b8,	 #		/* send 1 persons (In)visible status ( 0 = off, 1 = on ) */
);
my %client_commands_bynumber = reverse %client_commands;
##############################################################################
sub new {
   my $prototype = shift;
   my $host = shift;
   my $port = shift;

   srand();
   
   my $class = ref($prototype) || $prototype;
   my $self  = {};

   $self->{"host"} = $host || $Default_ICQ_Host;
   $self->{"port"} = $port || $Default_ICQ_Port;
   chomp($self->{"tty"} = `tty`);
   
   $self->{'login'} = 0;
   $self->{'uin'} = '0';
   
   $self->{'sectionid'} = int rand(0xFFFFFFFF);
   $self->{'seq1'} = int rand(0xFFFF);
   $self->{'seq2'} = 0;

   # open the connection
   $self->{"socket"} = new IO::Socket::INET (
      PeerAddr => $self->{"host"},
      PeerPort => $self->{"port"},
      Proto => "udp",
      Type => SOCK_DGRAM,
   ) || croak "new: connect socket: $!";

   $self->{"select"} = new IO::Select [$self->{"socket"}];

   bless($self, $class);
   return $self;
}
##############################################################################
sub DESTROY {
   my $self = shift;

   shutdown($self->{"socket"}, 2);
   close($self->{"socket"});

   return 1;
}
##############################################################################
#------------------------------------------------------------------------------
#Data
#
#A930BA39 - Ctime
#0F040000 - port
#0900     - Pwd len
#697738327069727300 - Password
#78000000 - X1
#2D2D3133 - IP
#06       - X2
#00000000 - Status
#02000000 - X3
#00000000 - X4
#20003F00 - X5
#50000000 - X6
#03000000 - X7
#ACFA5B38 - X8
#050EC137 - X9
#00000000 - X10
#00000000 - X10
#1A00 - Logo len
#4B5869637120302E342E302C207777772E6B786963712E6F7267 - Logo

#KXicq 0.4.0, www.kxicq.org

sub login {
   my $self = shift;

   my $uin = shift;
   my $password = shift;
   my $status = shift;
   my $mirror = shift;
   my $uins = shift;

   my $data_pack;

   $self->{'uin'} = $uin || '0';
   $self->{'password'} = $password || 'aaaa';
   $self->{'status'} = $status || 'STATUS_ONLINE';
   $self->{'mirror'} = $mirror || 0;
   $self->{'contactlist'} = $uins;
   
   $self->{'login'} = 1;
   
   $self->print_and_log_string(">> $scriptname",$color{'yelow'});
   $self->print_and_log_string(">> LOGIN: $self->{'uin'}/'$self->{'password'}' STATUS: $self->{'status'} MIRROR: $self->{'mirror'}");

   my $logo = "ICQ Inc. - Product of ICQ (TM)";

   $data_pack = pack("VVva*VVcvVVVVVVVVVvva*",
                     0x3b55d144,
		     $self->{'socket'}->sockport,	       # PORT
		     length($self->{'password'})+1,            # PASSWD LEN
		     $self->{'password'} . "\x0",	       # PASSWORD
                     0x000b013f, # X1
		     0x014ea8c0, # USER_IP
		     0x04,       # X2
		     defined($user_status_bynumber{$self->{'status'}}) ? $self->{'status'} : $user_status{'STATUS_ONLINE'},
		     0x00060012, # - X3
		     0x00000000, # - X4
		     0x00020000, # - X5
		     0x0050013f, # - X6
		     0x00030000, # - X7
		     0xc8eb0000, # - X8
		     0x0e053b46, # - X9
		     0x000037c1, # - X10
		     0x00000000, # - X11
		     0x0000,     # - X12 
		     length($logo) + 1,
		     $logo . "\x0");
		     
   $self->send_packet_V5($self->construct_packet_V5("C_LOGIN", $data_pack));

   return 1;
}
##############################################################################
sub incoming_packet_waiting {
   my $self = shift;
   my $timeout = shift;

   return $self->{'select'}->can_read($timeout);
}
##############################################################################
# ACK after login packet
#0500
#00
#67458B2B - Section ID
#0A00 - Command
#C623 - Seq1
#0100 - Seq2
#CE0CBB01 - uin
#E59E3105 - ?
sub incoming_process_packet {
   my $self = shift;

   my $server;
   my $packet;
   
   if(!$self->{'login'}) {return undef;}

   my $sock = $self->{"socket"};

   unless ($sock->recv($packet, 99999)) {
      croak "socket:  recv2:  $1";
   }

   $self->log_incoming_packet($packet);
   
   my ($version,$unknown,$sectionid,$command,$seq1,$seq2) = unpack("vcVvvv",$packet);
   
   $self->{'icq_packet_info'} = [$version,$command,$sectionid,$seq1,$seq2];
   
   if($server_commands_bynumber{$command})
       {
       $self->log_string("COMMAND: $server_commands_bynumber{$command}" . sprintf(" (%#04X)",$command) . "," . sprintf(" seq: %#08X,%#04X,%#04X",$self->{'sectionid'},$seq1,$seq2));
       }
   else
       {
       $self->print_and_log_string("ERROR: RECEIVED UNKNOWN PACKET TYPE: '$command/" . &decimal_to_hex($command) . sprintf(" seq: %#08X,%#04X,%#04X",$self->{'sectionid'},$seq1,$seq2));
       $self->send_ack_V5($seq1,$seq2);
       return 0;
       }
   
   if ($command eq $server_commands{"S_ACK"}) {
       $self->print_and_log_string("<< ACK");
       return 1;
       }
       
   my $command_name = "receive_" . $server_commands_bynumber{$command};
   my $coderef = $self->can($command_name);
   if ($coderef) 
       {
       $self->send_ack_V5($seq1,$seq2);
       my $ret=$self->$command_name($packet);
       return $ret;
       }
   else
       {
       $self->print_and_log_string("ERROR: SUBROUTINE FOR: '$server_commands_bynumber{$command}' NOT DEFINED :(");
       $self->send_ack_V5($seq1,$seq2);
       return 0;
       }	
}
##############################################################################

#0500
#00000000 - Zero
#CE0CBB01 - Uin
#67458B2B - Section ID
#0A00     - Command
#0000     - Seq1
#0000     - Seq2
#00000000 - Zero
#ABD77E50 - random

sub send_ack_V5 {
   my $self = shift;
   my $seq1 = shift;
   my $seq2 = shift;

   $self->print_and_log_string(">> ACK");
   return $self->send_packet_V5($self->construct_packet_V5("C_ACK",
       pack("V",int rand(0xFFFFFFFF)),$seq1,$seq2));
}
#############################################################################   
sub version {
   return "Net::ICQV5 v$VERSION by Sergei A. Nemarov";
}
#############################################################################   
sub log_string {
   my $self = shift;
   my $string = shift || '';

   if($logfileison)
       {
       open(FILE,">>$logfile");
       print FILE "$string\n";
       close(FILE);
       }
   if($logstringison && $allowoutput)
       {
       print "$string\n";
       }
}
#############################################################################   
#------------------------------------------------------------------------------
#Header
#
#0500     - Packet version
#00000000 - Zero
#CE0CBB01 - uin
#67458B2B - Section ID
#E803     - Command
#C623     - Seq 1
#0100     - Seq 2
#00000000 - Zero
#------------------------------------------------------------------------------
sub construct_packet_V5 {
   my $self = shift;
   my $command = shift;
   my $data = shift || '';
   my $seq1 = @_ ? shift : ++$self->{'seq1'};
   my $seq2 = @_ ? shift : ++$self->{'seq2'};

   my $packet;

   if(!$client_commands{$command})
       {
       $self->print_and_log_string("ERROR: CLIENT COMMAND '$command' NOT DEFINED");
       return $packet;
       }
       
   my $uin = $self->{'uin'};
   $self->log_string("Construct_packet:");
   $self->log_string("command: '$command' - ". &decimal_to_hex($client_commands{$command}));
   $self->log_string(sprintf("seq: %#08X,%#04X,%#04X",$self->{'sectionid'},$seq1,$seq2));
   $self->log_string("uin: '$uin'");
   
   $packet = 
         pack("vVVVvvvV", $ICQ_Version, 
	               0x00000000,
		       $uin,
		       $self->{'sectionid'},
                       $client_commands{$command},
		       $seq1,
		       $seq2,
  	               0x00000000) . $data;

   return $packet;
}
#############################################################################   
sub send_packet_V5 {
   my $self = shift;
   my $packet = shift;
   my $cryptflag = @_ ? shift : 1; # can be 0

   my $lenpacket=length($packet);

   if($cryptflag)
       {
       $self->log_string("$separator");
       $self->log_string("$pkgnum: SEND V5 (BEFORE CRYPT) ($lenpacket):\n" . unpack("H*",$packet));   
       $packet=ICQV5_CRYPT_PACKET($packet);
       $lenpacket=length($packet);
       $self->log_string("$pkgnum: SEND V5 (AFTER CRYPT) ($lenpacket):\n" . unpack("H*",$packet));
       $pkgnum++;
       }
   else
       {
       $self->log_string("$separator");
       $lenpacket=length($packet);
       $self->log_string("$pkgnum: SEND V5 (WITHOUT CRYPT) ($lenpacket):\n" . unpack("H*",$packet));
       $pkgnum++;
       }

   if (!defined(syswrite($self->{"socket"}, $packet, length($packet)))) {
      carp "syswrite: $!";
      return 0;
   }

   return 1;
}
#############################################################################   
sub decimal_to_hex {
   return sprintf("%#04X", $_[0]);
}
#############################################################################   
sub receive_S_GET_MESSAGE {
   my $self = shift;
   my $packet = shift;

   return unless defined $packet;

   my @convertedtext=();

   my ($version,$command,$sn,$uin,$type,$tlen,$text) = unpack("vvvVvva*", $packet);
   
   $self->log_string("COMMAND: $server_commands_bynumber{$command} TYPE: $message_types_by_bynumber{$type}");
   
   if($message_types_by_bynumber{$type} eq "TCP_MSG")
       {
       $text = substr($text,0,$tlen-1);
       my $ctext=$self->win2koi($text);
       $self->print_and_log_string("UIN: " . $uin . " WROTE: $ctext",$color{'yelow'});
       if($self->{'mirror'})
           {
	   $self->send_msg($uin,$ctext . ' ');
	   }
       }
   elsif($message_types_by_bynumber{$type} eq "TCP_URL")
       {
       $text = substr($text,0,$tlen-1);
       my $ctext=$self->win2koi($text);
       my @urlpair = split(/\xfe/,$ctext);
       $self->print_and_log_string("UIN: " . $uin . " URL:$urlpair[1] DESC: $urlpair[0]",$color{'green'});
       if($self->{'mirror'})
           {
	   $self->send_url($uin,$urlpair[1],$urlpair[0] . ' ');
	   }
       }
   elsif($message_types_by_bynumber{$type} eq "TCP_ADDED")
       {
       $self->print_and_log_string("You added by " . $uin,$color{'yelow'});
       }
   else
       {
       $self->print_and_log_string("ERROR: DON'T KNOW HOW TO PROCESS $message_types_by_bynumber{$type}");
       }

   return 0;
}
#############################################################################   
#packet: len: 53
#0500
#00
#67458B2B
#5A00
#0000
#0100
#CE0CBB01 - User Uin
#E59E3105 - User IP
#C2BA8A4B - Login Seq
#01000B00190000008C000000F0000A000A0005000A0001E7B6D67701

sub receive_S_LOGIN_REPLY {
   my $self = shift;
   my $packet = shift;

   # Cut header
   $packet = substr($packet,13);
   my ($user_uin,$user_ip,$login_seq) = unpack("VVV", $packet);

   $self->print_and_log_string("<< RECEIVE LOGIN REPLY - UIN=$user_uin");

   # NOW we can do the rest of the login stuff
#   $self->send_packet($self->construct_packet("C_LOGIN_1"));
#   $self->send_packet($self->construct_packet("C_LOGIN_2",pack("C", 0)));

#050000000000CE0CBB0167458B2B0604
#C723
#0200
#00000000
#173AF9F4017FBB0100D2D23D0482B70901642DFD02B2D6740038D501001123DE024E61BC00F0E68B0197FA6F02230169022B0EEA007AA37F031A9A2502CDD8F60468B33E0450DF100391645C043884F30035D11305325E1D05D6C1F301

   $self->send_contactlist(keys %{ $self->{'contactlist'} });
   $self->change_status($self->{'status'});

   return 1;
}
#############################################################################   
sub send_contactlist {
   my $self = shift;
   my @uins = @_;

   $self->print_and_log_string(">> CONTACTLIST UINs:" . join(", ",@uins));

   my $data = pack("c", scalar(@uins));
   foreach (@uins) {
      $data .= pack("V",$_);
   }

   return $self->send_packet_V5($self->construct_packet_V5("C_CONTACT_LIST", $data));
}
#############################################################################   
sub change_status {
   my $self = shift;
   my $status = shift;

   return undef unless defined($user_status{$status});
   
   $self->print_and_log_string(">> CHANGE STATUS: $status - $user_status{$status}");

   return $self->send_packet_V5($self->construct_packet_V5("C_STATUS_CHANGE",pack("V",$user_status{$status})));
}
#############################################################################   
sub receive_S_END_CONTACTLIST_STATUS {
   my $self = shift;
   my $message = shift;

   $self->print_and_log_string("<< END CONTACTLIST STATUS");
   return 0;
}
#############################################################################   
sub receive_S_SYSMESSAGE_DONE {
   my $self = shift;
   my $message = shift;

   $self->print_and_log_string("<< END_OFFLINE_MESSAGES");
   return $self->send_packet_V5($self->construct_packet_V5("C_ACK_MSG",
              pack("V",int rand(0xFFFFFFFF))));
}
#############################################################################   
sub receive_S_RECEIVE_MESSAGE {
   my $self = shift;
   my $message = shift;

   my ($version,$command,$sn,$uin,$year,$month,$day,$hour,$minute,$type,$tlen,$text)=
      unpack("vvvVvCCCCvva*", $message);  

   receive_S_GET_MESSAGE(pack("vvvVvva*",$version,$command,$sn,$uin,$type,$tlen,$text));
   return 0;
}
#############################################################################   
sub send_msg {
   my $self = shift;
   my $uin = shift;
   my $message = shift;

   if($uin eq 'last' || $uin eq 'l') {$uin=$self->{"lastuinmsg"};}
   else 
       {
       if(!($uin =~ /\d+/)) {return undef;}
       $self->{"lastuinmsg"} = $uin;
       }
   
   $self->print_and_log_string(">> SEND MSG to $uin : '$message'");
   my $cmessage = $self->koi2win($message);
   return $self->send_packet_V5($self->construct_packet_V5("C_SEND_MESSAGE",
          pack("Vvva*", $uin, $message_types{"TCP_MSG"}, length($message) + 1, $cmessage . "\0")));
}
#############################################################################   
sub send_url {
   my $self = shift;
   my $uin = shift;
   my $url = shift;
   my $desc = shift;

   if($uin eq 'last' || $uin eq 'l') {$uin=$self->{"lastuinmsg"};}
   else 
       {
       if(!($uin =~ /\d+/)) {return undef;}
       $self->{"lastuinmsg"} = $uin;
       }
   
   $self->print_and_log_string("$color{'ligthgreen'}>> SEND URL to '$uin' : URL: '$url' DESC: '$desc'$color{'normal'}");
   my $curl = $self->koi2win($url);
   my $cdesc = $self->koi2win($desc);
   return $self->send_packet_V5($self->construct_packet_V5("C_SEND_MESSAGE",
          pack("Vvva*", $uin, $message_types{"TCP_URL"}, length($curl) + length($cdesc) + 2, $cdesc . "\xfe" . $curl . "\0")));
}
#############################################################################   
sub receive_S_SILENT_TOO_LONG {
   my $self = shift;

   $self->print_and_log_string("<< SILENT TOO LONG");
   return $self->send_keepalive();
}
#############################################################################   
sub print_and_log_string {
   my $self = shift;
   my $string = shift;
   my $maincolor = shift;

   log_string($string);   
   
   if(!$maincolor)
       {
       if($string =~ m|>>|gi)
           {
	   $maincolor = $color{'ligthgreen'};
	   }
       elsif($string =~ m|<<|gi)
           {
	   $maincolor = $color{'ligthred'};
	   }
       elsif($string =~ m|ERROR:|gi)
           {
	   $maincolor = $color{'red'};
	   }
       else
           {
	   $maincolor = $color{'red'};
	   }
       }

   if($allowoutput)
       {print "\n$maincolor*** $string$color{'normal'}\n";}
}
#############################################################################   
sub send_keepalive {
   my $self = shift;

   $self->print_and_log_string(">> KEEPALIVE");
   return $self->send_packet_V5($self->construct_packet_V5("C_KEEP_ALIVE",
               pack("V",int rand(0xFFFFFFFF))));
}
#############################################################################   
sub select_mirror_mode {
   my $self = shift;
   my $mirror = shift;   
   
   $self->{'mirror'} = $mirror;
   if($self->{'mirror'})
       {
       $self->print_and_log_string("Mirror is On");
       }
   else
       {
       $self->print_and_log_string("Mirror is Off");
       }
}
#############################################################################   
sub receive_S_WRONG_PASSWORD {
   my $self = shift;
   
   $self->print_and_log_string("ERROR: WRONG PASSWORD");
   return undef;
}
#############################################################################   
sub logout {
   my $self = shift;
   
   my $msg = "B_USER_DISCONNECTED";
   
#050000000000CE0CBB0167458B2B3804
#CA230500
#00000000
#1400
#425F555345525F444953434F4E4E454354454400
#0500

   $self->print_and_log_string(">> LOGOUT");
   $self->send_packet_V5($self->construct_packet_V5("C_SEND_TEXT_CODE",
          pack("va*v",length($msg) + 1, $msg . "\0",0x05)));

   $self->{'login'} = 0;
   $self->{'uin'} = '0';
	  
   return 1;
}
#############################################################################   
sub log_incoming_packet {
   my $self = shift;
   my $packet = shift;

   my $lenpacket=length($packet);
 
   $self->log_string("$separator");
   $self->log_string("$pkgnum: RECEIVE ($lenpacket):\n" . unpack("H*",$packet));
   $pkgnum++;
}
#############################################################################   
sub regnewuser {
   my $self = shift;
   my $passwd = shift || $self->GenerateRandomString(4);
   my $email = shift || '';

   my %out;   
   $out{'error'} = 1;
   
   if($self->{'login'})
       {
       $self->print_and_log_string("ERROR: CAN'T REGNEW USER. LOG OUT FIRST.");
       $out{'error'} = "ERROR: CAN'T REGNEW USER. LOG OUT FIRST.";
       return %out;
       }
       
   $self->print_and_log_string(">> NEW USER WITH PASSWD: '$passwd' EMAIL: '$email'");
   
   my $client = '{KXicq 0.4.0}';
   my $section = int rand(0x0FFFFFFF);
   my $seqn   = int rand(0x0FFF);
   
   my $packet = 
   pack("vVVVvvvVva*VVVVva*va*VVc",0x05, 
                       0x00000000,
                       0x00000000,
                       $section,
                       $client_commands{'C_NEW_USER_REG'},
                       $seqn,
                       0x0001,
                       0x00000000,
		       length($passwd)+1,
		       $passwd . "\x0",
		       0xA0,
		       0x2461,
		       0xA00000,
		       0x00000000,
		       length($email)+1,
		       $email . "\x0",
		       length($client)+1,
		       $client . "\x0",
		       0x00000000,
		       0x00000000,
		       0x03,
		       );

   $self->send_packet_V5($packet);
   
   next_wait_p:
   if(!$self->incoming_packet_waiting())
       {
       $self->print_and_log_string("ERROR: CAN'T REG NEW USER. TIMEOUT.");
       $out{'error'} = "ERROR: CAN'T REGNEW USER. TIMEOUT.";
       return %out;
       }
       
   my $sock = $self->{"socket"};

   unless ($sock->recv($packet, 99999)) {
      croak "socket:  recv2:  $1";
   }
   $self->log_incoming_packet($packet);
   
   my ($version,$command,$unknown1,$uin) = unpack("vvVV",$packet);
   
   if ($command eq $server_commands{'S_REG_DENY'})
       {
       $self->print_and_log_string("ERROR: CAN'T REG NEW USER. SERVER DENY.");
       $out{'error'} = "ERROR: CAN'T REGNEW USER. SERVER DENY.";
       return %out;
       }
   if ($command ne $server_commands{'S_NEW_USER_UIN'}) {
       goto next_wait_p;
       }
     
   ### Send logout packet

   my $textcode = "B_USER_DISCONNECTED";

#   0500 - Version
#   00000000 - zero
#   00000000 - uin
#   67458B2B - section_id
#   3804 - cmd 
#   C723 - seq_num
#   0200
#   00000000 - sero
#   1400 - len_text_cmd
#   425F555345525F444953434F4E4E454354454400 - text_cmd
#   0500   
   
   $packet = pack("vVVVvvvVva*v",0x05, 
                       0x00000000,
                       0x00000000,
                       $section,
                       $client_commands{'C_SEND_TEXT_CODE'},
                       $seqn+1,
                       0x0002,
                       0x00000000,
		       length($textcode)+1,
		       $textcode . '\x0',
		       0x05,
		       );
		       
   $self->send_packet_V5($packet);
   
   $self->print_and_log_string("USER WITH UIN: '$uin' PASSWORD: '$passwd' CREATED",$color{'yelow'});

   $out{'uin'} = $uin;
   $out{'password'} = $passwd;
   $out{'email'} = $email;
   $out{'error'} = 0;
   
   return %out;
}
#############################################################################   
sub GenerateRandomString {
     my $self = shift;
     my $num = shift ;
 
    my $outstring ='';
    
    for(my $y=0;$y<$num;$y++)
	{
	my $rndnum  = int rand($#rndletters);
	my $letter  = $rndletters[$rndnum];
	$outstring = "$outstring$letter";
	}
   return $outstring; 
}
#############################################################################   
sub turnlog {
   my $self = shift;
   my $mode = shift;
   
   $logfileison = $mode;
}
#############################################################################   
sub turnoutput {
   my $self = shift;
   my $mode = shift;
   
   $allowoutput = $mode;
}
#############################################################################   
sub win2koi() 
    { 
    $_ = $_[0]; 
    tr /¿áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ/¿Â×ÞÚÄÅÃßÊËÌÍÎÏÐÒÔÕÆÈÖÉÇÀÙÜÑÝÛØÁÓâ÷þúäåãÿêëìíîïðòôõæèöéçàùüñýûøáó/; 
    return $_; 
    } 
sub koi2win() 
    { 
    $_ = $_[0]; 
    tr /¿Â×ÞÚÄÅÃßÊËÌÍÎÏÐÒÔÕÆÈÖÉÇÀÙÜÑÝÛØÁÓâ÷þúäåãÿêëìíîïðòôõæèöéçàùüñýûøáó/¿áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ/;
    return $_; 
    } 
#############################################################################   

1;

=head1 DISCLAIMERS

I am in no way affiliated with Mirabilis!

This module was made without any help from Mirabilis or their
consent.  No reverse engineering or decompilation of any Mirabilis
code took place to make this program.

=head1 COPYRIGHT

Copyright (c) 2000-2001 Sergei A. Nemarov (admin@tapor.com). All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

http://www.tapor.com/NetICQ/

=cut
