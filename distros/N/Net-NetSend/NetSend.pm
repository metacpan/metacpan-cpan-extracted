package Net::NetSend;

use 5.006;
use strict;
use warnings;
use POSIX;
use Socket qw(:DEFAULT :crlf);
use IO::Handle;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::NetSend ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( sendMsg getNbName ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();
our $VERSION = '0.12';

# Preloaded methods go here.


my $SESSION_REQUEST = chr(0x81);
my $INIT_SESSION_FLAGS = "\0";
my $NB_SESSION_MESSAGE	= "\0";
my $NB_SESSION_ESTABLISHED = chr(0x82);
my %NB_ERROR_TEXT = ( 0x83 => "Called Name Not Present" );
my %NB_ERROR_HELP = ( 0x83 => 'Probably the Messenger Service ("Nachrichtendienst") '
				."on the remote machine is switched off." );

#SMB Header
my $SMB_HEADER_SERVER_COMPONENT_SMB = chr(0xFF).chr(0x53).chr(0x4D).chr(0x42);
my $SMB_HEADER_SEND_SINGLE_BLOCK_MSG = chr(0xD0);
my $SMB_HEADER_SEND_MULTI_BLOCK_MSG_START = chr(0xD5);
my $SMB_HEADER_SEND_MULTI_BLOCK_MSG_TEXT = chr(0xD7);
my $SMB_HEADER_SEND_MULTI_BLOCK_MSG_END = chr(0xD6);
my $SMB_HEADER_ERROR_CLASS_SUCCESS = "\0";
my $SMB_HEADER_RESERVED = "\0";
my $SMB_HEADER_ERRORCODE_NO_ERROR = "\0"."\0";
my $SMB_HEADER_FLAGS_DEFAULT = "\0";
my $SMB_HEADER_FLAGS2_DEFAULT = "\0"."\0";
my $SMB_HEADER_PROCESS_ID_HIGH_FALSE = "\0"."\0";
my $SMB_HEADER_SIGNATURE = "\0"x 8;
my $SMB_HEADER_RESERVED2 = "\0"."\0";
my $SMB_HEADER_TREE_ID = "\0"."\0";
my $SMB_HEADER_PROCESS_ID = "\0"."\0";
my $SMB_HEADER_USER_ID = "\0"."\0";
my $SMB_HEADER_MULTIPLEX_ID = "\0"."\0";

my $MBM_MESSAGE_GROUP_ID;

#SSMBR = Send Single Block Message Request
my $SMB_SSBMR_BUFFER_ASCII = chr(0x04);
my $SMB_SSBMR_BUFFER_DATA_BLOCK = chr(0x01);

my $init_response_success = chr(0x82).("\0"x3);


my $overall_succes=1;				#Status
my $error_texts="";				#Error information storage


sub sendMsg($$$$;$){
	$@='';
	$error_texts='';
#	if(@_ < 4){
#		$@ .= "Not enough arguments.\n";
#		return 0;
#	}
	my $target_netbios_name_cleartext=uc(shift); 		# "Called Name"
	my $source_netbios_name_cleartext=uc(shift); 		# "Calling Name", can be faked here
	my $target_ip=shift;					# target ip.
	my $target_port=139;
	my $message=shift;					#The message to send
	my $debug=shift;

	if(length($message) <128){
		send_single_block_message(
		      	$message, $target_ip, $target_port, 
	      		$target_netbios_name_cleartext, 
	      		$source_netbios_name_cleartext,
	      		$debug
		);
		#print $error_texts if $error_texts;
		$@ = $error_texts;
		return $overall_succes;
	}
	if(length($message) > 4000){
		$error_texts .= "Warning! Message size exceeds 4000 chars. Truncated message will be delivered.\n";
		$message=substr($message, 0, 4000);
		$overall_succes=0;
	}
	#	print "Error: Message exceeds 128 Bytes.\n";
	#	exit(-1);
	send_multi_block_message(
	      $message, $target_ip, $target_port, 
	      $target_netbios_name_cleartext, 
	      $source_netbios_name_cleartext,
	      $debug
	);
	$@ = $error_texts;
	return $overall_succes;
}


sub getNbName($;$){
	(my $target_ip, my $debug) = @_;
	my $target_port = 137;
	print "Looking for a netbios name for $target_ip...\n" if $debug;

	#####################################
	#     	   Create Query Packet	    #
	#####################################

	my $nbq=''; #nbq = netbios name query
	#first 2 bytes = random transaction id
	$nbq .= chr(rand(142)+1);
	$nbq .= chr(rand(142)+1);
	# then: 2 bytes for flags (none set)
	$nbq .= chr(0)x2;
	# then: 2 bytes for the number of questions (one)
	$nbq .= chr(0).chr(0x01);
	# then: 2 bytes each for answer, authority and additional RRs (none)
	$nbq .= chr(0)x6;
	# then: the actual query. name first
	$nbq .= " CK".("A"x30).chr(0);
	# then: type (NBSTAT)
	$nbq .= chr(0).chr(0x21);
	# then: class (inet)
	$nbq .= chr(0).chr(0x01);
	# packet is now ready for delivery
	

	#####################################
	#     	   Create Socket	    #
	#####################################
	my $proto = getprotobyname("udp");
	my $host = inet_aton($target_ip) or die "Unknown host: $target_ip\n";
	my $sock;
	socket($sock, AF_INET, SOCK_DGRAM, $proto) or die "Could not create socket. Socket() failed: $!\n";
	my $dest_addr = sockaddr_in($target_port, $host);
	connect($sock, $dest_addr) 
		or die "connect() of socket to target IP $target_ip failed: $!\n";
	$sock->autoflush(1);

	#####################################
	# 	  Send Name Query	    #
	#####################################

	print $sock $nbq;
	
	#####################################
	#       Receive & Check Answer	    #
	#####################################
	my $nbanswer;

	my $answer_received=0;
	my $inmask = ''; 
	vec($inmask, fileno($sock), 1) = 1;
	while (select(my $outmask = $inmask, undef, undef, 0.8)) {
		recv($sock, $nbanswer, 1000, 0);
		$answer_received = 1;
	}

	if(!$answer_received){ 
		$@="Timeout while waiting for answer from $target_ip.\n";
		print $@ if $debug;
		return 0;
	}
	
	if(length($nbanswer) == 0){
		$@ = "Zero length answer received. Often this caused".
			  " by an ICMP destination unreacheable packet.\n";
		print $@ if $debug;
		return 0;
	}
			 
	if(length($nbanswer) < 20){
		$@ = "Too short answer (" . length($nbanswer) . 
			  " chars) received:\n" . hexdump($nbanswer);
		print $@ if $debug;
		return 0;
	}
	# strip header
	$nbanswer = substr($nbanswer, 12);
	# counting from 0
	# 42/43: data length
	# 44: number of names
	# now n 18-byte-steps, the wanted name ends with 0x03 0x04 0x00
	
	my $num_answers = ord(substr($nbanswer, 44, 1));
	
	my @names03=();

	for(my $i = 0; $i < $num_answers; $i++){
		my $service = substr($nbanswer, 44+ 16+ $i*18, 1);
		my $typeflags = substr($nbanswer, 44+ 17+ $i*18, 2);
		if($debug){ 
			print "\nCandidate $i\n"; 
			print hexdump(substr($nbanswer, 44+ $i*18, 16));
			print "\tService ".hexdump($service);
			print "\n\tTypeflags ".hexdump($typeflags)."\n\n";
		}
		# we got our target?
		if($service eq chr(0x03)){
			# && ($typeflags eq chr(0x04).chr(0) || $typeflags eq chr(0x44).chr(0))){
			# we got it! 
			# service 0x03 is the messenger service / main name
			# typeflags 0x04 0x00 means B-node, unique, active
			my $target_name = substr($nbanswer, 44+$i*18+1, 16);
			$target_name =~ /^(\S+)( )*/;
			push @names03, $1;
		}
	}
	return $names03[0] if @names03 > 0; 
	# @names[0] is the machine name
	# @names[1..n] are the users that are logged on
	$@ = "Sorry, you cannot send messages to this IP. " . 
		"There is no messenger service running on the remote machine\n" .
	   	"The complete answer was: " . hexdump($nbanswer) . "\n";
	print $@ if $debug;
	
#	print $num_answers;

	return 0;

}


sub send_multi_block_message{
	my $mbmessage 				= shift;
	my $mbtarget_ip 			= shift;
	my $mbtarget_port 			= shift;
	my $mbtarget_netbios_name_cleartext 	= shift;
	my $mbsource_netbios_name_cleartext 	= shift;
	my $confirm_packets			= shift;
	
	#Create Socket
	my $sock;
	my $proto = getprotobyname("tcp");
	my $host = inet_aton($mbtarget_ip) or die "Unknown host: $mbtarget_ip.\n";
	socket($sock, AF_INET, SOCK_STREAM, $proto) or die "Could not create socket. Socket() failed: $!\n";
	my $dest_addr = sockaddr_in($mbtarget_port, $host);
	connect($sock, $dest_addr) 
		or die "connect() of socket to $mbtarget_netbios_name_cleartext (IP: $mbtarget_ip) failed: $!\n";
	$sock->autoflush(1);

	#Compute Encoding for Source and Target NETBIOS Names
	my $target_netbios_name_cipher	= get_nb_string($mbtarget_netbios_name_cleartext);
	my $source_netbios_name_cipher	= get_nb_string($mbsource_netbios_name_cleartext);

	#Create Netbios Session Request Packet
	my $init_packet = $SESSION_REQUEST . $INIT_SESSION_FLAGS .
		get_2bytes_length($target_netbios_name_cipher.$source_netbios_name_cipher) . 
		$target_netbios_name_cipher . $source_netbios_name_cipher;
	
	#Send Netbios Session Request Packet
	print $sock $init_packet;

	#Receive Session Request Response
	my $init_resp="";
	my $inmask='';
	vec($inmask, fileno($sock), 1)=1;
	select(my $outmask = $inmask, undef, undef, 0.25); #0.25 sec timeout
	recv($sock, $init_resp,1024, 0);
		#print "received data: $init_resp\n";
		#print_to_file("c:\\test.log", $init_resp);


	#Check Session Request Response for Success
	if( $init_resp !~ /^$NB_SESSION_ESTABLISHED/){
		my $error = ord(substr($init_resp,0,1));
		$error_texts .= "Warning! Session request failed.\n";
		$error_texts .= "Opcode: ".$error." (0x".sprintf("%.0x", $error).")\n";
		$error_texts .= "Reason: " . $NB_ERROR_TEXT{$error} . ".\n\n";
		$error_texts .= $NB_ERROR_HELP{$error} . "\n";
		$overall_succes=0;
		return;
#		$error_texts .= "Warning: Session request failed.\nOpcode: 0x".sprintf("%.0x", ord(substr($init_resp, 0, 1)))."\n";
#		$overall_succes = 0;
#		return;
	}
	else{
		print "Session established.\n" if $confirm_packets;
	}
	
	#Create "Start of Multi-Block Message" Packet
	my $smbmrs_header = get_SMB_header($SMB_HEADER_SEND_MULTI_BLOCK_MSG_START);
	my $smbmrs_body   = get_SMB_body(
		$mbsource_netbios_name_cleartext, 	#source
		$mbtarget_netbios_name_cleartext, 	#target
		undef, 			#message
		$SMB_HEADER_SEND_MULTI_BLOCK_MSG_START  #type
	);
	
	#Netbios - Encapsulate "Start of Multi-Block Message" Request
	my $ssbmr_packet = netbios_session_encaps($smbmrs_header.$smbmrs_body, $NB_SESSION_MESSAGE);

	#Send "Start of Multi-Block Message" Request
	print $sock $ssbmr_packet;

	$MBM_MESSAGE_GROUP_ID = receive_and_check_answer_packet($sock, 
					"Start of Multi Block Message failed", 
					"MBM start", 
					$confirm_packets, 
					0);

#	print "\n\nGroup id: ". ord($MBM_MESSAGE_GROUP_ID) . "\n\n";

	#split message into parts
	my @messageparts;
	for(my $start =0; $start < length($mbmessage); $start+=128){
		push @messageparts, substr($mbmessage, $start, 128);
	}
	

	#send each part of the message
	my $teilcounter = @messageparts;
	for(my $i = 0; $i < $teilcounter; $i++){
		send_part_mbm($messageparts[$i], $teilcounter, $sock, $confirm_packets);
	}
	#$teilcounter=4;
	send_mbm_end($teilcounter, $sock, $confirm_packets);

}

sub send_mbm_end{
	my $msg_group_id 	= shift;
	my $sock 		= shift;
	my $confirm_packets 	= shift;
	
	my $smb_body = chr(0x01) 
#		. chr($msg_group_id)
		. $MBM_MESSAGE_GROUP_ID
		. ("\0"x3)
	;
	my $smb_header=get_SMB_header($SMB_HEADER_SEND_MULTI_BLOCK_MSG_END);
	my $mbm_packet = netbios_session_encaps($smb_header.$smb_body, $NB_SESSION_MESSAGE);
	print $sock $mbm_packet;
	receive_and_check_answer_packet($sock, "End of multi block message request failed", "MBM end", $confirm_packets, 0);
}

sub send_part_mbm{
	my ($msg, $teilcounter, $sock, $confirm_packets) = @_;
	my $smb_multi_header = get_SMB_header($SMB_HEADER_SEND_MULTI_BLOCK_MSG_TEXT);
	my $smb_multi_body = 
		chr(0x01) 					#Word Count
		. $MBM_MESSAGE_GROUP_ID . "\0" 			#Group ID alias "Byte Count"
		. chr(length($msg)+3)				#Not "Buffer format" but message length plus 3! 
		. "\0" . chr(0x01)				#Message Length??? = 256???
		. chr(length($msg))				#Not "Buffer format" but exact message length!
		. "\0"						#unknown
		. $msg						#Message text
	;

	my $mbm_packet = netbios_session_encaps($smb_multi_header.$smb_multi_body, $NB_SESSION_MESSAGE);
	select(undef, undef, undef, 0.05); #0.05 sec sleep
	print $sock $mbm_packet;

	receive_and_check_answer_packet($sock, "Part of multi block message request failed", "MBM text", $confirm_packets, 0);
	
}

sub receive_and_check_answer_packet{

	my $sock = shift;
	my $warning = shift;
	my $packet_desc = shift;
	my $confirm_success = shift;
	my $die = shift;
	
	my $resp="";
	my $inmask='';
	vec($inmask, fileno($sock), 1)=1;
	select(my $outmask = $inmask, undef, undef, 0.25);
	recv($sock, $resp,1024, 0);

	if (length($resp) < 10){
		# crippled or no answer received
		my $error = "No answer from remote Host";
		$error_texts .= "Warning: $warning.\n$error\n";
		$overall_succes=0;
		die if $die;
		return -1;
	}
	
	if(substr($resp,9,1) ne $SMB_HEADER_ERROR_CLASS_SUCCESS){
		my $error = ord(substr($resp,9,1));
		$error_texts .= "Warning: $warning.\n";
		$error_texts .= "Opcode: ". $error ." (0x".sprintf("%.0x", $error).")\n";
		$overall_succes=0;
		die if $die;
	}
	else{
			print "$packet_desc ACKed.\n" if $confirm_success;
	}

	return substr($resp, -4, 1);
	#return Message Group ID (needed for all MBM packets except start)
}

sub send_single_block_message{
	my $sbmessage 				= shift;
	my $target_ip 				= shift;
	my $target_port 			= shift;
	my $target_netbios_name_cleartext 	= shift;
	my $source_netbios_name_cleartext 	= shift;
	my $confirm_packets			= shift;


	my $target_netbios_name_cipher	= get_nb_string($target_netbios_name_cleartext);
	my $source_netbios_name_cipher	= get_nb_string($source_netbios_name_cleartext);


	my $init_packet = $SESSION_REQUEST . $INIT_SESSION_FLAGS .
		get_2bytes_length($target_netbios_name_cipher.$source_netbios_name_cipher) . 
		$target_netbios_name_cipher . $source_netbios_name_cipher;

	#send $init_packet
	#receive answer
	my $ssbmr_header = get_SMB_header($SMB_HEADER_SEND_SINGLE_BLOCK_MSG);
	my $ssbmr_body = get_SMB_body($source_netbios_name_cleartext, 
				$target_netbios_name_cleartext, 
				$sbmessage,
				$SMB_HEADER_SEND_SINGLE_BLOCK_MSG);
	my $ssbmr_packet = $ssbmr_header . $ssbmr_body;
	$ssbmr_packet = netbios_session_encaps($ssbmr_packet, $NB_SESSION_MESSAGE);
	#print_to_file("c:\\test.log", $ssbmr_header.$ssbmr_body);
	#send ssbmr


	#####################################
	#     	   Create Socket	    #
	#####################################
	my $proto = getprotobyname("tcp");
	my $host = inet_aton($target_ip) or die "Unknown host: $target_ip\n";
	my $sock;
	socket($sock, AF_INET, SOCK_STREAM, $proto) or die "Could not create socket. Socket() failed: $!\n";
	my $dest_addr = sockaddr_in($target_port, $host);

	connect($sock, $dest_addr) 
		or die "connect() of socket to $target_netbios_name_cleartext (IP: $target_ip) failed: $!\n";
	$sock->autoflush(1);

	#####################################
	# Send Session Request (init_packet)#
	#####################################

	print $sock $init_packet;
	
	#####################################
	#       Receive & Check Answer	    #
	#####################################


	my $init_resp="";
	my $answer_received=0;
	my $inmask = ''; 
	vec($inmask, fileno($sock), 1) = 1;
	while (select(my $outmask = $inmask, undef, undef, 0.4)) {
		recv($sock, $init_resp, 1024, 0);
		$answer_received = 1;
	}

	if(!$answer_received){ 
		if($confirm_packets){
			print "Timeout while waiting for answer from $target_ip.\n"
		}
		return 0;
	}




#	my $init_resp="";
#	my $inmask='';
#	vec($inmask, fileno($sock), 1)=1;
#	select(my $outmask = $inmask, undef, undef, 0.25);
#	recv($sock, $init_resp,1024, 0);
	#print "Daten empfangen: $init_resp\n";
	#print_to_file("c:\\test.log", $init_resp);

	if( $init_resp !~ /^$NB_SESSION_ESTABLISHED/){
		my $error = ord(substr($init_resp,0,1));
		$error_texts .= "Warning! Session request failed.\n";
		$error_texts .= "Opcode: ".$error." (0x".sprintf("%.0x", $error).")\n";
		$error_texts .= "Reason: " . $NB_ERROR_TEXT{$error} . ".\n";
		$error_texts .= $NB_ERROR_HELP{$error} . "\n";
		$overall_succes=0;
		return;
	}
	else{
		print "Session established.\n" if $confirm_packets;
	}

	#####################################
	#         Send Single Block Message (ssbmr)	#
	#####################################

	print $sock $ssbmr_packet;

	receive_and_check_answer_packet($sock, "Single block message request failed", "SBM Message", $confirm_packets, 0);
		 
	#################################
	#            END OF SUB  :-D  	#
	#################################
}

sub netbios_session_encaps{
	my $smb_packet=shift;
	my $enctype=shift;
	die "Unsupported encoding type in netbios_session_encaps()" if $enctype ne $NB_SESSION_MESSAGE;
	return $enctype . $INIT_SESSION_FLAGS . get_2bytes_length($smb_packet) . $smb_packet;
}


sub get_SMB_body{
	my $source=shift;
	my $target=shift;
	my $message=shift;
	my $type = shift;

	my $body;
	$body .= $SMB_SSBMR_BUFFER_ASCII;
	$body .= $source."\0";
	$body .= $SMB_SSBMR_BUFFER_ASCII;
	$body .= $target . "\0";
	if($type eq $SMB_HEADER_SEND_SINGLE_BLOCK_MSG){
		#add a buffer with the message to packet
		#not needed for a multi-msg start or end packet
		$body .= $SMB_SSBMR_BUFFER_DATA_BLOCK;
		$body .= swap_bytes(get_2bytes_length($message));
		$body .= $message;
	}
	#now prepend the body with Word Count (WCT) and Byte Count (BCC)
	#ONLY VALID for single block messages and start of multi block messages 
	my $wordcount = "\0"; 
	my $bytecount  = swap_bytes(get_2bytes_length($body));
	$body=$wordcount . $bytecount . $body;
}





sub get_nb_string{
	return ms_adjust_fle(first_level_encode(shift));
}

sub ms_adjust_fle{
	#chr(0x20) is at position -1 
	my $fle=shift;
	chop $fle;
	chop $fle;
	$fle.=chr(0x41).chr(0x44)."\0";
	return chr(0x20) . $fle;
}

sub print_to_file{
	my $path	= shift;
	my $string	= shift;
	if(shift){
		open OUT, ">>$path";
		print OUT $string;
		close OUT;
	}
	else{
		open OUT, ">$path";
		print OUT $string;
		close OUT;
	}
}

sub get_2bytes_length{
	my $string=shift;
	if (length($string) > 0xFF){
		my $first = floor(length($string)/0x100);
		my $second = length($string)-$first;
		return chr($first).chr($second);
	}
	return "\0".chr(length($string));
}

sub swap_bytes{
	my $count = shift;
	my $first = substr($count, 0, 1);
	my $second = substr($count, 1, 1);
	return ($second.$first);
}

sub print_hex{
	my $string = shift;
	print "\nph:\n";
	for(my $i=-1; $i<length($string); $i++){
		print substr($string, $i, 1), " ", sprintf("%.0x", ord(substr($string, $i, 1))), "\n";
	}
	print "\nende ph\n";
}

sub first_level_encode{ #see RFC 1001, Section 14.1.
	my $net_name = uc(shift) || die "first_level_encode called without params.\n";
	my $debug=shift || 0;
	my $encoded_name="";
	#size < 16 => pad with blanks
	$net_name .= " "x 16;
	$net_name=substr($net_name, 0, 16);
	my $char;
	for(my $i=0; $i<16; $i++){
		$char=substr($net_name, $i, 1);
		if($debug){print "Char: ".$char."    ";}
		my $first	=floor(ord($char)/16);
		my $second=ord($char) - 16*$first;
		$first	=chr($first+0x41);
		$second	=chr($second+0x41);
		$encoded_name.=$first.$second;
		if($debug){print "$first$second\n";}
	}
	return $encoded_name;
}
	
sub get_SMB_header{
	my $type=shift;
	die("Unknown SMB Header Type requested") if (
		$type ne $SMB_HEADER_SEND_SINGLE_BLOCK_MSG &&
		$type ne $SMB_HEADER_SEND_MULTI_BLOCK_MSG_START &&
		$type ne $SMB_HEADER_SEND_MULTI_BLOCK_MSG_TEXT &&
		$type ne $SMB_HEADER_SEND_MULTI_BLOCK_MSG_END 
		);
	my $header = $SMB_HEADER_SERVER_COMPONENT_SMB . 
		$type .
		$SMB_HEADER_ERROR_CLASS_SUCCESS .
		$SMB_HEADER_RESERVED .
		$SMB_HEADER_ERRORCODE_NO_ERROR .
		$SMB_HEADER_FLAGS_DEFAULT .
		$SMB_HEADER_FLAGS2_DEFAULT .
		$SMB_HEADER_PROCESS_ID_HIGH_FALSE .
		$SMB_HEADER_SIGNATURE .
		$SMB_HEADER_RESERVED2 .
		$SMB_HEADER_TREE_ID .
		$SMB_HEADER_PROCESS_ID .
		$SMB_HEADER_USER_ID .
		$SMB_HEADER_MULTIPLEX_ID;
	return $header;
}
	
sub hexdump{
	my $text = shift;
	my $hexdump = "";
	for(my $i = 1; $i <= length($text); $i++){
		$hexdump .= two(sprintf("%.0x", ord(substr($text, $i-1, 1))));
		$hexdump .=  "00" if substr($text, $i-1, 1) eq chr(0x00);
		$hexdump .= " ";
		$hexdump .= "\n" if ($i % 8 == 0 && $i != 0);
	}
	return $hexdump;
}

sub two{
	my $param = shift;
	return "0".$param if length($param)==1;
	return $param;
}

#END{
#	print $error_texts;
#}



1;
__END__

=head1 NAME

Net::NetSend - Perl extension for sending Windows Popup Messages

=head1 SYNOPSIS

  use Net::NetSend qw(:all);
  
  my $target_netbios_name;
  my $source_netbios_name = "mypc";
  my $target_ip = "192.168.0.1";
  my $message = "Hello World!";
  my $debug = 0;  
  
  $target_netbios_name = getNbName($target_ip, $debug);
  if(!$target_netbios_name){
  	die "No netbios name found: $@\n";
  }

  my $success = sendMsg($target_netbios_name, $source_netbios_name, $target_ip, $message, $debug);
  print ($success ? "Delivery successfull\n" : "Error in delivery! \n$@\n");

=head1 DESCRIPTION

This module implements a client interface to the Windows Messenger Service, 
enabling a perl5 application to talk to windows machines. This is a pure Perl 
implementation that approximates the "net send" command on Windows.

=head2 EXPLANATION

The source netbios name may be chosen freely and does not need to match your real
netbios name.

Both target netbios name and target IP are needed when sending a message. However, 
since version 0.12 this module includes a routine to lookup the netbios name of 
a given IP. A lookup procedure vice versa is not implemeted in this module yet. 
You're welcome to add it and send me a patch. If noone else volunteers for this 
task, I intend to do this myself when I've got some spare time for it. 

The target IP can be a numerical IP like it is shown above or a hostname like 
host.domain.tld.

The message can be any arbitrary string. If it is greater than 4000 chars the 
message will still be delivered but truncated to 4000 chars. If you _really_ want to
send more text than 4000 chars you can split your message into parts of the 
respective maximum of 4000 chars and call sendMsg() for all parts consecutively. In 
this case be sure to have a look at the CAVEATS section a few lines down this page.

Debug is intended to print more status information in case of difficulties. In general
it works like a "verbose" switch. The parameter "debug" is optional and defaults to 0. 
It can be one or zero. Zero means "No, don't print debug messages.", one means "Yes, 
please print debug messages to STDOUT."

By default (debug off), sendMsg() does not print anything in case of success. In 
case of a failure it prints an error message.

=head2 CAVEATS

This module expects answers from the remote machine when a connection has been 
successfully established. If the remote machine stops responding after the 
connection has been established it might hang for some time (forever?). You can 
use the alarm function to be sure this does not happen. As this situation is 
extremely rare you probably don't need it. But if you intend to send thousands 
of messages at once you should probably do it. 

Be advised that you need a short pause (one second is more than enough) between
two messages to the same machine. No pause is needed between messages to different
machines.

If sendMsg() fails it will call die(). If you don't want your program to exit
when sending a message to one machine fails (because you want it to try 
delivering the message to another machine) you have to encapsulate the call to 
sendMsg() in an eval statement.

=head2 EXPORT

None by default.
:all exports sendMsg() and getNbName()

=head1 NOTES

This module was tested with Windows XP, Windows 98, Windows NT and Linux.
It should work on any other operating system as well. Drop me a note
if you encounter errors, giving the exact circumstances of the failure and a 
listing of the output with debug enabled. A packet dump would be helpful, too.

Maximum Message size is 4000 bytes.

=head1 CHANGES

B<new in 0.02>

=over 12

=item C<*>

bugfix last message of multi block message

=item C<*>

check MBM text packet return codes for success

=back

=over 12

B<new in 0.04>

=item C<*>

check restriction of 4021 chars maximum message length

=item C<*>

Warnings AF_INET / SOCK_STREAM eliminated

=item C<*>

check MBM END packet return codes

=item C<*>

extra function for error checking in SMB return packets

=item C<*>

sendMsg now returns success/error code
	

=back

=over 12

B<new in 0.05>

=item C<*>

abort if session request fails

=item C<*>

set $@ if error occurs

=item C<*>

change some global vars to local ones
	

=back

=over 12

B<new in 0.06>

=item C<*>

comment cleanup

=item C<*>

add flexible debug messages	


=back

=over 12

B<new in 0.07>

=item C<*>

useless "no strict" outcommented	

=item C<*>

fixed a bug that happened when splitting messages containing newlines

=item C<*>

added documentation
	

=back

=over 12

B<new in 0.08>

=item C<*>

added contact information

=item C<*>

bugfix for error handling $@

=item C<*>

module renamed to Net::NetSend

=item C<*>

argument count check

=item C<*>

4022 bytes -E<gt> 4021 chars


=back

=over 12

B<new in 0.10>

=item C<*>

POD documentation

=back


=over 12

B<new in 0.11>

=item C<*>

Cut message size to 4000 chars. This is more safe. 
Before, sending could fail if message length plus 
source netbios name plus target nebios name were 
greater than 4032 chars. 

=item C<*>

An accidentally German error message was translated to 
English and extended to give more information about 
the error. Thanks to Tom Metro for reporting this 
and some other things.

=item C<*>

Documentation about caveats added.

=item C<*>

Bugfix for accumulating error texts as reported by 
brae.charles at mail.com. (Thanks!) 

=item C<*>

POD documentation extended.

=item C<*>

Error messages improved to give more information about the 
error.

=back

=over 12

B<new in 0.12>

=item C<*>

Added capability of looking up netbios names by IP address.

=item C<*>

Minor code adjustements.


=back

=head1 AUTHOR

Florian Greb, E<lt>greb@cpan.orgE<gt>


=head1 COPYRIGHT

Copyright (c) 2004-2005 Florian Greb. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
