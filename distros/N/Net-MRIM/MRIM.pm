#
# $Date: 2009-01-11 21:41:07 $
#
# Copyright (c) 2007-2008 Alexandre Aufrere
# Licensed under the terms of the GPL (see perldoc MRIM.pm)
#

use 5.008;
use strict;

# below is just an utility class
package Net::MRIM::Message;

use constant {
 TYPE_UNKNOWN	=> 0,
 TYPE_MSG		=> 1,
 TYPE_LOGOUT_FROM_SRV	=> 2,
 TYPE_CONTACT_LIST	=> 3,
 TYPE_SERVER	=> 4
};

sub new {
	my ($pkgname)=@_;
	my $self={}; 
	$self->{_type}=TYPE_UNKNOWN;
	$self->{TYPE_SERVER_NOTIFY}=0;
	$self->{TYPE_SERVER_ANKETA}=1;
	$self->{TYPE_SERVER_AUTH_REQUEST}=2;
	bless $self;
	return $self;
}

sub set_message {
	my ($self, $from, $to, $message)=@_;
	$self->{_type}=TYPE_MSG;
	$self->{_from}=$from;
	$self->{_to}=$to;
	$self->{_message}=$message;
}

sub is_message{
	my ($self)=@_;
	return ($self->{_type}==TYPE_MSG);
}

sub get_from {
	my ($self)=@_;
	return $self->{_from};
}

sub get_to {
	my ($self)=@_;
	return $self->{_to};
}

sub get_message {
	my ($self)=@_;
	return $self->{_message};
}

sub set_logout_from_server {
	my ($self)=@_;
	$self->{_type}=TYPE_LOGOUT_FROM_SRV;
}

sub is_logout_from_server {
	my ($self)=@_;
	return ($self->{_type}==TYPE_LOGOUT_FROM_SRV);
}

sub set_server_msg {
	my ($self,$stype,$to,$message,$svalue)=@_;
	$self->{_type}=TYPE_SERVER;
	$self->{_stype}=$stype;
	$self->{_from}='SERVER';
	$self->{_to}=$to;
	$self->{_message}=$message;
	$self->{_from}=$svalue if ($stype==$self->{TYPE_SERVER_AUTH_REQUEST});
}

sub is_server_msg {
	my ($self)=@_;
	return ($self->{_type}==TYPE_SERVER);
}

sub get_subtype {
	my ($self)=@_;
	return $self->{_stype};
}

sub set_contact_list {
	my ($self, $groups, $contacts)=@_;
	$self->{_type}=TYPE_CONTACT_LIST;
	$self->{_groups}=$groups;
	$self->{_contacts}=$contacts;
}

sub is_contact_list {
	my ($self)=@_;
	return ($self->{_type}==TYPE_CONTACT_LIST);
}

sub get_groups {
	my ($self)=@_;
	return $self->{_groups};
}

sub get_contacts {
	my ($self)=@_;
	return $self->{_contacts};
}

package Net::MRIM::Contact;

sub new {
	my ($pkgname,$email,$name,$status)=@_;
	my $self={};
	$self->{_email}=$email;
	$self->{_name}=$name;
	$self->{_status}=$status;
	$self->{STATUS_ONLINE}=0x00000001;
	$self->{STATUS_AWAY}=0x00000002;
	bless $self;
	return $self;
}

sub get_email {
	my $self=shift;
	return $self->{_email};
}

sub get_name {
	my $self=shift;
	return $self->{_name};
}

sub get_status {
	my $self=shift;
	return $self->{_status};
}

sub set_status {
	my ($self,$status)=@_;
	$self->{_status}=$status;
}

package Net::MRIM;

our $VERSION='1.11';

=pod

=head1 NAME

Net::MRIM - Perl implementation of mail.ru agent protocol

=head1 DESCRIPTION

This is a Perl implementation of the mail.ru agent protocol, which specs can be found at http://agent.mail.ru/protocol.html

=head1 SYNOPSIS

To construct and connect to MRIM's servers:

 my $mrim=Net::MRIM->new(
 			Debug=>0,
 			PollFrequency=>5
 			);
 $mrim->hello();

To log in:

 if (!$mrim->login("login\@mail.ru","password")) {
	print "LOGIN REJECTED\n";
	exit;
 } else {
	print "LOGGED IN\n";
 }

To authorize a user:

 my $ret=$mrim->authorize_user("friend\@mail.ru");

To add a user to contact list (sends automatically auth request):

 $ret=$mrim->add_contact("friend\@mail.ru");

To remove a user from contact list:

 $ret=$mrim->remove_contact("friend\@mail.ru");

To send a message:

 $ret=$mrim->send_message("friend\@mail.ru","hello");

To change user status:

 $ret=$mrim->change_status(status);

Where status=0 means online and status=1 means away

Get information for a contact:

 $ret=$mrim->contact_info("friend\@mail.ru");
 
Search for users:

 $ret=$mrim->search_user(email, sex, country, online);

Where sex=(1|2), country can be found at http://agent.mail.ru/region.txt or in Net::MRIM::Data.pm, and online=(0|1)

Analyze the return of the message:

 if ($ret->is_message()) {
	print "From: ".$ret->get_from()." Message: ".$ret->get_message()." \n";
 } elsif ($ret->is_server_msg()) {
 	print $ret->get_message()." \n";
 }

Looping to get messages:

 while (1) {
	sleep(1);
	$ret=$mrim->ping();
	if ($ret->is_message()) {
		print "From: ".$ret->get_from()." Message: ".$ret->get_message()." \n";
	}
 }

Disconnecting:

 $mrim->disconnect();

=head1 AUTHOR

Alexandre Aufrere <aau@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007-2008 Alexandre Aufrere. This code may be used under the terms of the GPL version 2 (see at http://www.gnu.org/licenses/old-licenses/gpl-2.0.html). The protocol remains the property of Mail.Ru (see at http://www.mail.ru).

=cut

use IO::Socket::INET;
use IO::Select;

# the definitions below come straight from the protocol documentation
use constant {
 CS_MAGIC		=> 0xDEADBEEF,
 PROTO_VERSION	=> 0x10008,

 MRIM_CS_HELLO 	=> 0x1001,	## C->S, empty   
 MRIM_CS_HELLO_ACK 	=> 0x1002,	## S->C, UL mrim_connection_params_t

 MRIM_CS_LOGIN2      => 0x1038,	## C->S, LPS login, LPS password, UL status, LPS useragent
 MRIM_CS_LOGIN_ACK 	=> 0x1004,	## S->C, empty
 MRIM_CS_LOGIN_REJ 	=> 0x1005,	## S->C, LPS reason
 MRIM_CS_LOGOUT		=> 0x1013,    ## S->C, UL reason

 MRIM_CS_PING 	=> 0x1006,	## C->S, empty

 MRIM_CS_USER_STATUS	=> 0x100f,	## S->C, UL status, LPS user
  STATUS_OFFLINE	 => 0x00000000,
  STATUS_ONLINE    => 0x00000001,
  STATUS_AWAY      => 0x00000002,
  STATUS_UNDETERMINED   => 0x00000003,
 MRIM_CS_USER_INFO		=> 0x1015,
 MRIM_CS_ADD_CONTACT 	=> 0x1019,  # C->S UL flag, UL group_id, LPS email, LPS name
  CONTACT_FLAG_VISIBLE	=> 0x00000008,
  CONTACT_FLAG_REMOVED	=> 0x00000001,
  CONTACT_FLAG_SMS	=> 0x00100000,
 MRIM_CS_ADD_CONTACT_ACK	=> 0x101A,
  CONTACT_OPER_SUCCESS	=> 0x00000000,
  CONTACT_OPER_USER_EXISTS	=> 0x00000005,
 MRIM_CS_AUTHORIZE		=> 0x1020,	# C -> S, LPS user
 MRIM_CS_MODIFY_CONTACT		=> 0x101B,	# C -> S, UL id, UL flags, UL group_id, LPS email, LPS name, LPS unused
 MRIM_CS_MODIFY_CONTACT_ACK	=> 0x101C,
 MRIM_CS_AUTHORIZE_ACK	=> 0x1021,	# C -> S, LPS user

 MRIM_CS_MESSAGE 		=> 0x1008,	## C->S, UL flags, LPS to, LPS message, LPS rtf-message
  MESSAGE_FLAG_OFFLINE	=> 0x00000001,
  MESSAGE_FLAG_NORECV	=> 0x00000004,
  MESSAGE_FLAG_AUTHORIZE	=> 0x00000008,
  MESSAGE_FLAG_SYSTEM	=> 0x00000040,
  MESSAGE_FLAG_RTF		=> 0x00000080,
  MESSAGE_FLAG_NOTIFY	=> 0x00000400,
  MESSAGE_FLAG_UNKOWN   => 0x00100000,
 MRIM_CS_MESSAGE_RECV	=> 0x1011,
 MRIM_CS_MESSAGE_STATUS	=> 0x1012, # S->C
 MRIM_CS_MESSAGE_ACK			=> 0x1009, #S->C
 MRIM_CS_OFFLINE_MESSAGE_ACK	=> 0x101D, #S->C UIDL, LPS message
 MRIM_CS_DELETE_OFFLINE_MESSAGE	=> 0x101E, #C->S UIDL

 MRIM_CS_CONNECTION_PARAMS =>0x1014, # S->C 

 MRIM_CS_CHANGE_STATUS	=> 0x1022,
 MRIM_CS_GET_MPOP_SESSION	=> 0x1024,
 MRIM_CS_MPOP_SESSION	=> 0x1025,

 MRIM_CS_ANKETA_INFO	=> 0x1028, # S->C
 MRIM_CS_WP_REQUEST		=>0x1029, # C->S
 MRIM_CS_MAILBOX_STATUS	=> 0x1033,
 MRIM_CS_CONTACT_LIST2	=> 0x1037, # S->C UL status, UL grp_nb, LPS grp_mask, LPS contacts_mask, grps, contacts

 MRIM_CS_SMS		=> 0x1039, # C->S UL unkown, LPS number, LPS message
 MRIM_CS_SMS_ACK	=> 0x1040, # S->C UL status

 # Don't look for file transfer, it's simply not handled
 # Mail.Ru only partially documented the old, unused P2P file transfer
 # the new file transfer simply gives an (unusable) RFC1918 address
 # when getting the MRIM_CS_FILE_TRANSFER packet
 # Needs some reverse-engineering. Has been done by Miranda's MRA plugin guys,
 # but for some reason i can't find the source

 MRIMUA => "Net::MRIM.pm v. "
};

use bytes;

# the constructor takes only one optionnal parameter: debug (true or false);
sub new {
	my ($pkgname,%params)=@_;
	my ($host, $port) = _get_host_port();
	my $sock = IO::Socket::INET->new(
				PeerAddr		=> $host,
				PeerPort		=> $port,
				Proto			=> 'tcp',
				Type			=> SOCK_STREAM,
				TimeOut			=> 20
			);
	die "couldn't connect" if (!defined($sock));
	print "DEBUG Connected to $host:$port\n" if (($params{Debug})&&($params{Debug}==1));
	my $self={};
	$self->{_sock}=$sock;
	$self->{_seq_real}=0;
	$self->{_ping_period}=30; # value by default
	# this stores the contact list:
	$self->{_contacts}={};
	# this stores the MRIM's UIDs for contacts (internal use only)
	$self->{_all_contacts}={};
	$self->{_debug}=$params{Debug} if (($params{Debug})&&($params{Debug}==1));
	$self->{_freq}=$params{PollFrequency} || 5;
	$self->{_freq}=30 if ($self->{_freq}>30);
	$self->{_last_seq}=-1;
	$self->{_last_type}=-1;
	$self->{_last_time}=time();
	print "DEBUG Poll Frequency: ".$self->{_freq}."\n" if ($self->{_debug});
	bless $self;
	return $self;
}

# this is the technical "hello" header
#  as a side note, it seems to me that this protocol was created by people who were used to e-mail ;-)
sub hello {
	my ($self)=@_;
	my $ret=$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_HELLO,""),0);
	my($msgrcv,$datarcv,$dlen)=_receive_data($self);
	$datarcv=unpack("V",$datarcv);
	$self->{_ping_period} = $datarcv;
	$self->{_seq_real}++;
	print "DEBUG Connected to MRIM. Ping period is $datarcv\n" if ($datarcv&&($self->{_debug}));
}

# normally useless
sub get_ping_period {
	my ($self)=@_;
	return $self->{_ping_period};
}

# the server should be ping'ed regularly to avoid being disconnected
sub ping {	
	my ($self)=@_;
	print "DEBUG [ping]\n" if ($self->{_debug});
	my $curtime=time();
	if (($curtime-$self->{_last_time})>=($self->{_ping_period}-10)) {
		$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_PING,""),0);	
		$self->{_seq_real}++;
		$self->{_last_time}=$curtime;
	}
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);
}

# this is to log in...
sub login {
	my ($self,$login,$pass)=@_;
	my $status=STATUS_ONLINE;
	print "DEBUG [status]: $status\n" if ($self->{_debug});
	my $data=_to_lps($login)._to_lps($pass).pack("V",$status)._to_lps("".MRIMUA.$VERSION);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_LOGIN2,$data));
	$self->{_seq_real}++;
	$self->{_login}=$login;
	my($msgrcv,$datarcv,$dlen)=_receive_data($self);
	my $norace=0;
	while (($msgrcv==0)&&($norace<50)) {
		($msgrcv,$datarcv,$dlen)=_receive_data($self);
		$norace++;
	}
	print "DEBUG [rcv login ack] $msgrcv\n" if ($self->{_debug});
	return ($msgrcv==MRIM_CS_LOGIN_ACK)?1:0;
}

# this is to send a message
sub send_message {
	my ($self,$to,$message)=@_;
	print "DEBUG [send message]: $message\n" if ($self->{_debug});
	my $data=pack("V",MESSAGE_FLAG_NORECV)._to_lps($to)._to_lps($message)._to_lps("");
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_MESSAGE,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);
}

# send SMS
# the implementation is awful: it adds and then remove an SMS entry to the contact list, and tries to send SMS in between.
# why ? i'm French, live in France, and don't have any access to a russian mobile phone... so it's impossible for me to test, i just use some web literature i found on the topic
# wish to help ? contact me - aau@cpan.org (vozmozhno i po-russkiy - lyudi! pomogite! ;-))))
sub send_sms {
	my ($self,$numberto,$message)=@_;
	my $dontremove=0;
	print "DEBUG [send SMS]: $message\n" if ($self->{_debug});
	# first, we should "add" it as SMS contact...
	my $data=pack("V",CONTACT_FLAG_SMS).pack("V",0xffffffff)._to_lps($numberto)._to_lps("SMS")._to_lps($numberto);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_ADD_CONTACT,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	my @datas=_from_mrim_us("uu",$datarcv);
	my $cid=$datas[1];
	# This is ugly: in case some message is in between, return without sending the SMS actually
	if ($msgrcv != MRIM_CS_ADD_CONTACT_ACK) {
		print "DEBUG [send SMS]: $message was NOT sent\n" if ($self->{_debug});
		return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);
	}
	# In case adding the contact failed, return without sending the SMS actually, but with an error message
	if (($datas[0] != CONTACT_OPER_SUCCESS)&&($datas[0] != CONTACT_OPER_USER_EXISTS)) {
		my $data=new Net::MRIM::Message();
		$data->set_server_msg($data->{TYPE_SERVER_NOTIFY},$self->{_login},"CONTACT_OPER_ERROR_SMS: Error adding contact for SMS sending");
		return $data;
	}
	$dontremove=1 if ($datas[0] == CONTACT_OPER_USER_EXISTS);
	$data=pack("V",0)._to_lps($numberto)._to_lps($message);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_SMS,$data));
	$self->{_seq_real}++;
	my ($msgrcvsms,$datarcvsms,$dlensms)=_receive_data($self);
	# if contact was already in contact list, do not try to remove it.
	return _analyze_received_data($self,$msgrcvsms,$datarcvsms,$dlensms) if ($dontremove==1);
	$data=pack("V",$cid).pack("V",CONTACT_FLAG_SMS|CONTACT_FLAG_REMOVED).pack("V",0xffffffff)._to_lps($numberto)._to_lps("SMS")._to_lps($numberto);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_MODIFY_CONTACT,$data));
	$self->{_seq_real}++;
	($msgrcv,$datarcv,$dlen)=_receive_data($self);
	# This is ugly: in case some message is in between, return without knowing if the SMS was actually sent
	if ($msgrcv != MRIM_CS_MODIFY_CONTACT_ACK) {
		return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);
	}
	return _analyze_received_data($self,$msgrcvsms,$datarcvsms,$dlensms);
}

# to authorize a user to add us to the contact list
sub authorize_user {
	my ($self,$user)=@_;
	my $data=_to_lps($user);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_AUTHORIZE,$data));
	$self->{_seq_real}++;	
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);	
}

# change user's status: 0=online, 1=away
sub change_status {
	my ($self,$status)=@_;
	my $data=pack('V',STATUS_ONLINE);
	$data=pack('V',STATUS_AWAY) if ($status==1);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_CHANGE_STATUS,$data));
	$self->{_seq_real}++;	
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);	
}

# to add a contact to the contact list
sub add_contact {
	my ($self, $email)=@_;
	print "DEBUG [add contact]: $email\n" if ($self->{_debug});
	my $data=pack("V",0).pack("V",0xffffffff)._to_lps($email).pack("V",0).pack("V",0);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_ADD_CONTACT,$data));
	$self->{_seq_real}++;
	# not in the protocol: after sending an add request, one should send an auth message !
	$data=pack("V",MESSAGE_FLAG_AUTHORIZE)._to_lps($email)._to_lps("Please authorize me")._to_lps("");
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_MESSAGE,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);	
}

# to remove a contact from the contact list
sub remove_contact {
	my ($self, $email)=@_;
	print "DEBUG [remove contact]: $email ".$self->{_all_contacts}->{$email}."\n" if ($self->{_debug});
	return new Net::MRIM::Message if (!defined($self->{_all_contacts}->{$email}));
	# C -> S, UL id, UL flags, UL group_id, LPS email, LPS name, LPS unused
	my $data=pack("V",$self->{_all_contacts}->{$email}).pack("V",CONTACT_FLAG_REMOVED).pack("V",0xffffffff)._to_lps($email).pack("V",0).pack("V",0);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_MODIFY_CONTACT,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	if ($msgrcv==MRIM_CS_MODIFY_CONTACT_ACK) {
		my @datas=_from_mrim_us("uu",$datarcv.pack("V",0));
		if ($datas[0]==0) {
			print "DEBUG $email removed from CL\n" if ($self->{_debug});
			$self->{_contacts}->{$email}=undef;
			$self->{_all_contacts}->{$email}=undef;
		}
	}
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);
}

# get contact info from server (send contact info request)
sub contact_info {
	my ($self, $email)=@_;
	$email=~m/^([a-z0-9\_\-\.]+)\@([a-z0-9\_\-\.]+)$/i;
	my $cuser=$1;
	my $cdomain=$2;
	my $data=pack("V",0x00000000)._to_lps($cuser).pack("V",0x00000001)._to_lps($cdomain).pack("V",0x00000009)._to_lps('1');
	print "DEBUG Getting infor for $cuser $cdomain\n" if ($self->{_debug});
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_WP_REQUEST,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);
}

# get contact avatar url
sub get_contact_avatar_url {
	my ($self, $email)=@_;
	$email=~m/^([a-z0-9\_\-\.]+)\@([a-z0-9\_\-]+)\.([a-z0-9\_\-]+)$/i;
	my $cuser=$1;
	my $cdomain=$2;
	return "http://avt.foto.mail.ru/$cdomain/$cuser/_avatar";	
}

# search users. for now only by nickname, sex, country
sub search_user {
	my ($self, $email, $sex, $country, $online)=@_;
	$email=~m/^([a-z0-9\_\-\.]+)\@([a-z0-9\_\-\.]+)$/i;
	my $cuser=$1;
	my $cdomain=$2;
	my $data='';
	$data.=pack("V",0x00000000)._to_lps($cuser).pack("V",0x00000001)._to_lps($cdomain) if ($email ne '');
	$data.=pack("V",0x00000005)._to_lps("$sex") if (($sex ne '')&&($sex ne '0'));
	$data.=pack("V",0x0000000F)._to_lps("$country") if ($country ne '');
	$data.=pack("V",0x00000009)._to_lps('1') if ($online == 1);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_WP_REQUEST,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv,$dlen)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv,$dlen);
}

# and finally to disconnect
sub disconnect {
	my ($self)=@_;
	$self->{_sock}->close;
}

#### private methods below ####

# build the MRIM packet accordingly to the protocol specs
sub _make_mrim_packet {
	my ($self,$msg, $data) = @_;
	my ($magic, $proto, $seq, $from, $fromport) = (CS_MAGIC, PROTO_VERSION, $self->{_seq_real}, 0, 0);
	# actually, i'm not even sure this is needed...
	$seq=$self->{_last_seq} if ($msg==MRIM_CS_MESSAGE_RECV);
	my $dlen = 0;
	$dlen = length($data) if $data;
	my $mrim_packet = pack("V7", $magic, $proto, $seq, $msg, $dlen, $from, $fromport);
	$mrim_packet.=pack("C[16]",0);
	$mrim_packet .= $data if $data;
	printf("DEBUG [send packet]: MAGIC=$magic, PROTO=$proto, SEQ=$seq, TYP=0x%04x, LEN=$dlen\n",$msg) if ($self->{_debug});
	return $mrim_packet;
}

# retrieve a real host:port, as "mrim.mail.ru" can be several servers
# note that we connect on port 443, as this will always work for sure...
sub _get_host_port {	
	my $sock = new IO::Socket::INET (		
			PeerAddr  => 'mrim.mail.ru',		
			PeerPort  => 443,		
			PeerProto => 'tcp', 		
			TimeOut   => 10	);
	my $data="";
	$sock->recv($data, 18);	
	close $sock;	
	chomp $data;
   	return split /:/,  $data;	
}

# reading the data from server
sub _receive_data {
	my ($self)=@_;
	my $buffer="";
	my $data="";
	my $typ=0;
	print "DEBUG [recv packet]: waiting for header data\n" if ($self->{_debug});
	return (MRIM_CS_LOGOUT,"",0) if ((!($self->{_sock}))||(!$self->{_sock}->connected()));
	my $s = IO::Select->new();
	$s->add($self->{_sock});
	# check, since socket registration *could* fail
	return (MRIM_CS_LOGOUT,"",0) if (!defined($s->exists($self->{_sock})));
	my $dllen=0;
	# this stuff is to not wait for ever data from the server
	# note that we're mixing a bit unbuffered and buffered I/O, this is not 100% great	
	if ($s->can_read(int($self->{_ping_period}/$self->{_freq}))) {
		$self->{_sock}->recv($buffer,44);
		my ($magic, $proto, $seq, $msg, $dlen, $from, $fromport, $r1, $r2, $r3, $r4) = unpack ("V11", $buffer);
		use bytes;
		if (($seq>0)&&($seq<=$self->{_last_seq})&&($msg==$self->{_last_type})) {
			# this should work, but it doesn't. since i don't understand, better leave it deactivated.
			#return(-1,"",0);
		} else {
			$self->{_last_type}=$msg;
			$self->{_last_seq}=$seq if ($seq>0);
		}
		$self->{_sock}->recv($buffer,$dlen);
		$data=$buffer;
		$typ=$msg;
		$dllen=$dlen;
		# unfortunately "buffer I/O" isn't that buffered... 
		while (length($data)<$dlen) {
			$self->{_sock}->recv($buffer,$dlen-length($data));
			$data.=$buffer;
		}
		printf("DEBUG [recv packet]: MAGIC=$magic, PROTO=$proto, SEQ=$seq, LASTSEQ=$self->{_last_seq}, TYP=0x%04x, LEN=$dlen ".length($data)."\n",$msg) if ($self->{_debug});
	}
	return ($typ,$data,$dllen);	
}

# the packet analyzer
sub _analyze_received_data {
	my ($self,$msgrcv,$datarcv,$dlen)=@_;
	$dlen = 0 if (!defined($dlen));
	my $data=new Net::MRIM::Message();
	if (!defined($msgrcv)) {
		$data->set_logout_from_server();
	} elsif ($msgrcv==MRIM_CS_OFFLINE_MESSAGE_ACK) {
		my $msg='';
		my @datas=_from_mrim_us("s",substr($datarcv,8,-1));
		LINE: foreach my $msgline (split(/\n/,$datas[1])) {
			# some headers cleanup
			if ($msgline!~m/^(Boundary:|Version:|X-MRIM-Flags:|Subject:|\-\-)/) {
				$msg.=$msgline."\n";
			}
			# remove everything past the boundary
			elsif ($msgline=~m/^\-\-[0-9A-Z]+/) {
				last LINE;
			}
		}
		$data->set_message("OFFLINE",$self->{_login},$msg);
		$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_DELETE_OFFLINE_MESSAGE,substr($datarcv,0,8)));
	} elsif ($msgrcv==MRIM_CS_MESSAGE_ACK) {
		my @datas=_from_mrim_us("uusss",$datarcv);
		# below is a work-around: it seems that sometimes message_flag is left to 0...
		# as well, it seems the flags can be combined...
		# lastly, this flag was recently added, i don't know why...
		while ($datas[1]>=MESSAGE_FLAG_UNKOWN) {
			$datas[1]=$datas[1] - MESSAGE_FLAG_UNKOWN;
		}
		if (($datas[1]==MESSAGE_FLAG_NORECV)||($datas[1]==MESSAGE_FLAG_OFFLINE)) {
			$data->set_message($datas[2],$self->{_login},"".$datas[3]);
		} elsif (($datas[1]==0)||($datas[1]==MESSAGE_FLAG_RTF)) {
			$data->set_message($datas[2],$self->{_login},"".$datas[3]);
			$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_MESSAGE_RECV,_to_lps($datas[2]).pack("V",$datas[0])));
		} elsif (($datas[1]==MESSAGE_FLAG_NOTIFY)||($datas[1]==(MESSAGE_FLAG_NOTIFY+MESSAGE_FLAG_NORECV))) {
			$data->set_message($datas[2],$self->{_login},"pishu") if ($self->{_debug});
		} elsif (($datas[1]==MESSAGE_FLAG_AUTHORIZE)
			||($datas[1]==(MESSAGE_FLAG_AUTHORIZE+MESSAGE_FLAG_NORECV))
			||($datas[1]==(MESSAGE_FLAG_AUTHORIZE+MESSAGE_FLAG_OFFLINE))
			) {
			$data->set_server_msg($data->{TYPE_SERVER_AUTH_REQUEST},$self->{_login},$datas[3],$datas[2]);
		} elsif (($datas[1]==MESSAGE_FLAG_SYSTEM)
			||($datas[1]==(MESSAGE_FLAG_SYSTEM+MESSAGE_FLAG_NORECV))
			||($datas[1]==(MESSAGE_FLAG_SYSTEM+MESSAGE_FLAG_OFFLINE))
			) {
			$data->set_server_msg($data->{TYPE_SERVER_NOTIFY},$self->{_login},$datas[3]);
		} else {
			print "DEBUG: ack msg $datas[1] from $datas[2] text: $datas[3]\n" if ($self->{_debug});
		}
	} elsif ($msgrcv==MRIM_CS_LOGOUT) {
		$data->set_logout_from_server();
	} elsif ($msgrcv==MRIM_CS_MAILBOX_STATUS) {
		my @datas=_from_mrim_us("u",$datarcv);
		$data->set_server_msg($data->{TYPE_SERVER_NOTIFY},$self->{_login},"NEW_MAIL: ".$datas[0]);
	} elsif ($msgrcv==MRIM_CS_CONTACT_LIST2) {
		# S->C UL status, UL grp_nb, LPS grp_mask, LPS contacts_mask, grps, contacts
		my @datas=_from_mrim_us("uuss",$datarcv);
		my $nb_groups=$datas[1];
		my $gr_mask=$datas[2];
		my $ct_mask=$datas[3];
		print "DEBUG: found $datas[1] groups, $datas[2] gr mask, $datas[3] contact mask\n" if ($self->{_debug});
		$datarcv=$datas[4];
		my $groups={};
		for (my $i=0; $i<$nb_groups; $i++) {
			my ($grp_id,$grp_name)=(0,"");
			($grp_id,$grp_name,$datarcv)=_from_mrim_us($gr_mask,$datarcv);
			print "DEBUG: Found group $grp_name of id $grp_id\n" if ($self->{_debug});
			$groups->{$grp_id}=$grp_name;
		}
		my $contacts=$self->{_contacts};
		my $all_contacts=$self->{_all_contacts};
		my $i=scalar(keys(%{$all_contacts}))+1;
		$i=20 if ($i<10);
		my $clen=8+length($gr_mask)+length($ct_mask);
		while ((length($datarcv)>1)||($clen < $dlen)) {
			# TODO works only with current pattern uussuus . if it changes, will break...
			my ($flags,$group, $email, $name, $sflags, $status, $unk)=(0,"");
			($flags,$group, $email, $name, $sflags, $status, $unk, $datarcv)=_from_mrim_us($ct_mask,$datarcv);
			$name=~s/\n//g;
			print "DEBUG: Found contact $name of id $email flags $flags $sflags $status $group unknown: $unk clen $clen dlen $dlen\n" if ($self->{_debug});
			$name=$email if (length($name)<1);
			$status=STATUS_OFFLINE if (($flags==CONTACT_FLAG_REMOVED)||($flags==CONTACT_FLAG_SMS)||($flags==(CONTACT_FLAG_SMS|CONTACT_FLAG_REMOVED))); # to take care about SMS contacts, if any
			$contacts->{$email}=new Net::MRIM::Contact($email,$name,$status) if (($status != STATUS_OFFLINE)&&($status != STATUS_UNDETERMINED)&&(length($email)>1));
			$all_contacts->{$email}=$i;
			$clen=16+length($name)+length($email)+length($unk)+$clen;
			$datarcv="" if($clen>$dlen);
			$i++;
		}
		$self->{_contacts}=$contacts;
		$self->{_all_contacts}=$all_contacts;
		$self->{_groups}=$groups;
		$data->set_contact_list($groups,$contacts);
	} elsif (($msgrcv==MRIM_CS_USER_STATUS)||($msgrcv==MRIM_CS_AUTHORIZE_ACK)) {
		# if user changes status, or has accepted to be added to our list,
		# then we should update the contact list accordingly
		my @datas=();
		if ($msgrcv==MRIM_CS_USER_STATUS) {
			@datas=_from_mrim_us("us",$datarcv);
		} else {
			my @tmp=_from_mrim_us("s",$datarcv);
			@datas=(STATUS_ONLINE,$tmp[0]);
		}
		my $contacts=$self->{_contacts};
		my $all_contacts=$self->{_all_contacts};
		my $groups=$self->{_groups};
		my @ckeys=keys%{$contacts};
		my $i=scalar(keys(%{$all_contacts}))+1;
		$i=20 if ($i<10);
		if (($datas[0] != STATUS_OFFLINE)&&($datas[0] != STATUS_UNDETERMINED)) {
			$contacts->{$datas[1]}=new Net::MRIM::Contact($datas[1],$datas[1],$datas[0]);
			$all_contacts->{$datas[1]}=$i;
		} elsif (($datas[0] == STATUS_OFFLINE)&&(grep(/$datas[1]/,@ckeys))) {
			$contacts->{$datas[1]}=undef;
			$all_contacts->{$datas[1]}=undef;
		}
		$self->{_contacts}=$contacts;
		$self->{_all_contacts}=$all_contacts;
		$data->set_contact_list($groups,$contacts);
	} elsif (($msgrcv==MRIM_CS_ADD_CONTACT_ACK)||($msgrcv==MRIM_CS_MODIFY_CONTACT_ACK)) {
		# this is useless for now, as the contact list only stores online users
		my @datas=_from_mrim_us("uu",$datarcv.pack("V",0));
		print "DEBUG add_contact_ack: $datas[0] $datas[1]\n" if ($self->{_debug});
		$data->set_contact_list($self->{_groups},$self->{_contacts});
		$data->set_server_msg($data->{TYPE_SERVER_NOTIFY},$self->{_login},"CONTACT_OPER_ERROR: Error adding/removing contact") if ($datas[0] != CONTACT_OPER_SUCCESS);
	} elsif ($msgrcv==MRIM_CS_ANKETA_INFO) {
		my @datas=_from_mrim_us("uuuu",$datarcv);
		my $dataparse="";
		for (my $i=0; $i<$datas[1]; $i++) { $dataparse.='ss'; }
		my $fulldata="INFO\n";
		my $fentr=0;
		print "DEBUG anketa_info: found ".$datas[0].' '.$datas[1].' '.$datas[2].' '.$datas[3]." entries\n" if ($self->{_debug});
		while (($fentr<$datas[2])&&($fentr<50)) {
			@datas=_from_mrim_us("uuuu".$dataparse,$datarcv);
			# this flag will trace if a record was found
			my $found=1;
			for (my $i=4;$i<($datas[1]+4);$i++) {
				my $label=$datas[$i];
				my $value=$datas[($i+$datas[1])];
				my $entry.=_to_lps($value);
				# this is to remove the entry from received data, to allow "iteration" ammong values
				$entry=~s/(\W)/\\$1/g;
				$datarcv=~s/$entry//;
				if ($label eq 'Username') {
					$found=0 if ($value eq '');
					$fulldata.="User\t\t: $value\@" if ($found==1);
				} elsif ($label eq 'Domain') {
					$fulldata.=$value."\n" if ($found==1);
				} elsif ($label eq 'Sex') {
					if ($value eq '1') {
						$value='Male';
					} elsif ($value eq '2') {
						$value='Female';
					} else {
						$value='Unknown';
					}
					$fulldata.=$label."\t\t: ".$value."\n" if ($found==1);
				} else {			
					$fulldata.=$label."\t: ".$value."\n" if ($found==1);
				}
			}
			$fentr++;
			# this is the separator between two entries
			$fulldata.="----------------------------------------\n" if ($found==1);
		}
		print "DEBUG anketa_info: $fulldata\n" if ($self->{_debug});
		$data->set_server_msg($data->{TYPE_SERVER_ANKETA},$self->{_login},$fulldata);
	} elsif ($msgrcv==MRIM_CS_USER_INFO) {
		my @datas=_from_mrim_us("ssss",$datarcv);
		$data->set_server_msg($data->{TYPE_SERVER_NOTIFY},$self->{_login},"$datas[0]: $datas[1] | $datas[2]: $datas[3]");
	} elsif ($msgrcv==MRIM_CS_SMS_ACK) {
		my @datas=_from_mrim_us("u",$datarcv);
		# actually, MRIM seems to return always "1"... so i leave the outpout only for debug
		$data->set_message("DEBUG",$self->{_login},"SMS ACK: $datas[0]") if ($self->{_debug});
		# wild guess that "0" should mean "SUCCESS"
		$data->set_server_msg($data->{TYPE_SERVER_NOTIFY},$self->{_login},"SMS_SENT") if ($datas[0]==0);
	} else {
		$data->set_message("DEBUG",$self->{_login},$datarcv) if ($self->{_debug});
	}
	return $data;
}

# this is to decode mrim's combination of ulong and lps that is sent as message data
sub _from_mrim_us {
	my ($pattern,$data)=@_;
	my @res=();
	for (my $i=0;$i<length($pattern);$i++) {
		my $datatype=substr($pattern,$i,1);
		if ($datatype eq 'u') {
			if ( $data=~m/^(\C{4})(\C*)/) {
				my $item=unpack("V",$1);
				$data=$2;
				push @res,$item;
			} else {
				push @res,0;
			}
		} elsif ($datatype eq 's') {
			$data=~m/^(\C{4})(\C*)/s;
			my $itemlength=$1;
			if ($itemlength) {
				$data=$2;
				$itemlength=unpack("V",$itemlength);
				if ($itemlength<4096) {
					$data=~m/^(\C{$itemlength})(\C*)/;
					my $item=$1;
					$data=$2;
					push @res,$item;
				} else {
					$data=~s/^\0//;
					push @res, "";
				}
			} else {
				push @res, "";
			}
		}
	}
	push @res,$data;
	return @res;
}

# convert to LPS (read the protocol !)
sub _to_lps {
	my ($str)=@_;
	return pack("V",length($str)).$str;
}

1;
