package Net::OICQ::ServerEvent;

# $Id: ServerEvent.pm,v 1.4 2007/06/15 18:09:53 tans Exp $

# Copyright (c) 2003 - 2006 Shufeng Tan.  All rights reserved.
# 
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)

use strict;
use warnings;

eval "no encoding; use bytes;" if $] >= 5.008;

use Crypt::OICQ qw(encrypt decrypt);
use Net::OICQ::ClientEvent;
our @ISA = qw(Net::OICQ::Event);

my $InfoHeader = \@Net::OICQ::InfoHeader;

sub new {
	my ($class, $data, $oicq) = @_;
	unless (defined $data and length($data) > 8) {
		$oicq->log_t("Discard data from server:\n", unpack("H*", $data)) if $oicq->{Debug};
		return;
	}
	my $time = time;
	$oicq->{LastSvrAck} = $time;
	my $self = {
		Time  => $time,
		OICQ  => $oicq,
		Header => substr($data, 0, 7),
	};
	bless $self, $class;
	my $cmdcode = $self->cmdcode;
	my $cmd     = $self->cmd;
	if ($cmd eq 'login' || $cmd =~ /^reg_new_id_/) {
		$oicq->log_t("Cmd $cmd ($cmdcode):\n", $oicq->hexdump($data));
		return undef;
	}
	if ($self->process) {
		my $crypt = substr($data, 7, -1);
		my $plain;
		eval { $plain = decrypt(undef, $crypt, $oicq->{Key}) };
		$oicq->log_t("Error in new ServerEvent:", unpack("H*", $self->{Header}), "$cmd\n", $@) if $@;
		return undef unless defined $plain;
		$self->{Data} = $plain;
		$oicq->log_t("Server mesg header: ", unpack("H*", $self->{Header}),
			" $cmd: ", unpack("H*", $self->{Data})) if $oicq->{Debug};
	}
	return $self;
}

# Server replies with user info
sub get_user_info {
	my ($self) = @_;
	my $oicq = $self->{OICQ};
	my $plain = $self->{Data};
	my @field = split(/$Net::OICQ::FS/, $plain);

	return unless defined $field[0];
	$self->{Info} = \@field;
	return if $field[0] =~ /^-/;

	# If the info is about myself, update MyInfo field.
	$oicq->{MyInfo} = [@field] if $field[0] == $oicq->{Id};

	# Initialize Info for the QQ id
	$oicq->{Info}->{$field[0]} = {} unless defined $oicq->{Info}->{$field[0]};
	# Update nickname, age, sex, and face(or avatar)
	my $hashref = $oicq->{Info}->{$field[0]};
	$hashref->{Nickname} = $field[1];
	$hashref->{Age}      = $field[7];
	$hashref->{Sex}      = $field[8];
	$hashref->{Face}     = $oicq->get_face($field[21]);

	# Update user info file
	my $datfile = "$oicq->{Dir}/$oicq->{Id}/$field[0].dat";
	my $dat = new FileHandle(">$datfile");
	if (defined $dat) {
		print $dat "\$_ = {\n";
		for(my $j = 0; $j<=$#field; $j++) {
			printf $dat "%-15s => '%s',\n", $InfoHeader->[$j], $field[$j];
		}
		print $dat "};\n";
		$dat->close;
	} else {
		$oicq->log_t("Failed to open user info file >$datfile");
	}

	return 1;
}

# Server return code is stored in $event->{ReturnCode}
sub send_msg {
	my ($self) = @_;
	my $oicq = $self->{OICQ};
	my $hex = unpack("H*", $self->{Data});
	$self->{ReturnCode} = $hex;
	return 1;
}

# recv_msg handles messages from QQ servers, other users, or groups
# These event attributes will be set: SrcId, DstId, MsgType, MsgTime, Mesg,
# SrcId2, DstId2, $oicq->{Info}->{$srcid}->{Client}, MsgSubtype, MsgSeq for user messages
# GrpId, GrpType, SrcId2 for group messages
# BotError if a chat bot is defined

sub recv_msg {
	my ($self) = @_;
	my $oicq  = $self->{OICQ};
	my $plain = $self->{Data};
	my ($srcid, $dstid, $x) = unpack('NNN', substr($plain, 0, 12));
	$self->{SrcId} = $srcid;
	$self->{DstId} = $dstid;
	$self->{N8_12} = $x;
	my $srcaddr = $oicq->show_address(substr($plain, 12, 6));
	my $msg_type = unpack('n', substr($plain, 18, 2));
	$self->{SrcAddr} = $srcaddr;
	$self->{MsgType} = $msg_type;

	if ($srcid != 10000 and !defined($oicq->{Info}->{$srcid})) {
		$oicq->{Info}->{$srcid} = {};
	}
	my $mesg;
	if (grep {$msg_type == $_} 0x09, 0x0a, 0x84, 0x85) {
		my ($client, $srcid2, $dstid2, $x, $subtype, $seq, $time) =
			unpack('H4NNH32nnN', substr($plain, 20, 34));
		$oicq->{Info}->{$srcid}->{Client} = $client;
		$self->{SrcId2} = $srcid2;
		$self->{DstId2} = $dstid2;
		$self->{H30_46} = $x;
		$self->{Subtype} = $subtype;
		$self->{MsgSeq} = $seq;
		$self->{MsgTime} = $time;
		if ($subtype == 0x81) { # Request for file transfer, voice or video
			#$mesg = unpack('H*', substr($plain, 54));
			$self->{RequestId} = unpack('H*', substr($plain, 94, 2));
			$self->{RequestIP} = $oicq->show_address(substr($plain, 96, 4));
			if ($plain =~ /([^\x1f]+?)\x1f(\d+) \xd7\xd6\xbd\xda$/s) {
				$self->{FileName} = $1;
				$self->{FileSize} = $2;
			} elsif ($plain =~ /(\xd3\xef\xd2\xf4\xc1\xc4\xcc\xec)/s) {
				$self->{VoiceChat} = $1;
			} elsif ($plain =~ /(\xd3\xef\xd2\xf4\xca\xd3\xc6\xb5\xc1\xc4\xcc\xec)/s) {
				$self->{VideoChat} = $1;
			} else {
				$self->{Ignore} = 1;
			}
		} elsif ($subtype == 0x85) { # Cancel
			#$mesg = unpack('H*', substr($plain, 54));
			$self->{RequestCancelled} = unpack('H*', substr($plain, 84, 2));
		} elsif ($subtype == 0x35) {
			$self->{Ignore} = 1;
			#$mesg = unpack('H*', substr($plain, 54));
		} elsif ($subtype == 0x0b) {
			$mesg = substr($plain, 73);
		} else {
			$mesg = substr($plain, 54);
		}
	} elsif ($msg_type == 0x20 or $msg_type == 0x2b) {  # Group message
		my ($gid, $gtype, $srcid2, $x1, $seq, $time, $x2, $len, $x3) =
			unpack('NH2NH4nNH8nH20', substr($plain, 20, 33));
		$self->{GrpId} = $gid;
		$self->{GrpType} = $gtype;
		$self->{SrcId2} = $srcid2;
		$self->{H9_10} = $x1;
		$self->{MsgSeq} = $seq;
		$self->{MsgTime} = $time;
		$self->{H17_20} = $x2;
		$self->{MsgLen} = $len;
		$self->{MsgHead} = $x3;
		$mesg = substr($plain, 53);
	}
	# Let's process the message tail
	if ($mesg) {
		my $tail_len = ord(substr($mesg, -1, 1));
		my $tail = substr($mesg, -1-$tail_len);
		if ($tail =~ /^ \0/) {
			# get rid of tail from $mesg
			substr($mesg, -1-$tail_len) = "";
			# don't care about bold, italic, or underscore
			$self->{FontSize} = ord(substr($tail, 2, 1)) & 0x1f;
			$self->{FontColor} = unpack('H*', substr($tail, 3, 3));
			$tail =~ s/.$//;
			$self->{FontName} = substr($tail, 9);
		}
		if ($oicq->{LogChat}) {
			my $grpid = exists($self->{GrpId}) ? "(Group $self->{GrpId})" : "";
			my $time = substr(localtime($self->{MsgTime}), 4, 16);
			$oicq->log_t("$time received message from $srcid$grpid:\n$mesg");
		}
	} elsif ($msg_type == 0x18) {
		$self->{MsgHeader} = unpack("H*", substr($plain, 20, 5));
		$mesg = substr($plain, 25);
	} elsif ($msg_type == 0x30) {
		$self->{MsgHeader} = unpack("H*", substr($plain, 20, 1));
		$mesg = substr($plain, 21);
	} elsif ($msg_type == 0x34) {  # Backdrop
		$self->{MsgTime} = unpack('N', substr($plain, -4));
		if (length($plain) <= 30) {
			$self->{BackdropCancelled} = 1;
			$mesg = "";
		} else {
			my $len = ord(substr($plain, 27, 1));
			$self->{Backdrop} = substr($plain, 28, $len);
			$mesg = substr($plain, 20);
		}
	} elsif ($msg_type == 0x41) {
		$self->{MsgHeader} = unpack("H*", substr($plain, 20, 9));
		$mesg = substr($plain, 29);
	} elsif ($msg_type == 0x4c) {
		$self->{MsgHeader} = unpack("H*", substr($plain, 20, 7));
		$mesg = substr($plain, 27);
	} elsif ($oicq->{Debug}) {
		$mesg = unpack('H*', substr($plain, 20));
		$oicq->log_t("Unknown message type $msg_type from $srcid, $srcaddr:\n$mesg");
	}
	$self->{Mesg} = $mesg;

	if (defined $oicq->{Socket} and defined $mesg and ! $self->{Ignore}) {
		$oicq->ack_msg($self->seq, $plain);
	}
	return 1;
}

# Response to get_online_friends is a list of fixed length (38 bytes)
# records, will update $oicq->{Info}, $event->{OnlineFriends}

sub get_online_friends {
	my ($self) = @_;
	my $plain = $self->{Data};
	my $oicq = $self->{OICQ};
	my @list = ();
	my $info = $oicq->{Info};
	for(my $i = 1; $i<length($plain); $i+=38) {
		my $fid =  unpack('N', substr($plain, $i, 4));
		my $addr = $oicq->show_address(substr($plain, $i+5, 6));
		my $mode = ord(substr($plain, $i+12, 1));
		my $key  = substr($plain, $i+13, 20);
		defined $info->{$fid} or $info->{$fid} = {};
		$info->{$fid}->{Key} = $key;
		$info->{$fid}->{Mode} = $mode;
		$info->{$fid}->{Addr} = $addr if $addr =~/[1-9]/;
		push @list, $fid;
	}
	$self->{OnlineFriends} = \@list;
	return 1;
}

sub recv_service_msg {
	my ($self) = @_;
	my $oicq = $self->{OICQ};
	my ($code, $srcid, $myid, $mesg) = split(/$Net::OICQ::RS/, $self->{Data});
	$self->{ServerCode} = $code;
	$self->{SrcId} = $srcid;
	$self->{DstId} = $myid;
	$self->{Mesg} = $mesg;
	if (defined $oicq->{Socket}) {
		$oicq->ack_service_msg($code, $srcid, $self->seq);
	}
	my $comment;
	if ($code eq "02" or $code eq "41") {
		$comment = "$srcid asked to add $myid";
	} elsif ($code eq "03") {
		$comment = "$srcid accepted $myid";
	} elsif ($code eq "04") {
		$comment = "$srcid rejected $myid";
	} elsif ($srcid == 10000) {
		$comment = "garbage from $srcid";
	} else {
		$comment = "unknown";
	}
	$self->{Comment} = $comment;
	$oicq->log_t("$comment:\n$mesg");
	return 1;
}

# List of lists is stored in $event->{UserList}

sub search_users {
	my ($self) = @_;
	my $plain = $self->{Data};
	my $oicq = $self->{OICQ};
	my @list;
	foreach my $line (split(/$Net::OICQ::RS/, $plain)) {
		my @f = split(/$Net::OICQ::FS/, $line);
		next unless defined $f[3];
		$f[3] = $oicq->get_face($f[3]);
		push @list, \@f;
	}
	$self->{UserList} = \@list;
	return 1;
}

sub keep_alive {
	my $self = shift;
	my $oicq = $self->{OICQ};
	my $plain = $self->{Data};
	#my @field = split($Net::OICQ::RS, $plain);
	#$oicq->{UserCount} = $field[2];
	#$self->{ServerInfo} = \@field;
	return 1;
}

sub get_contact_id {
	my ($self, $seq) = @_;
	my $event;
	foreach my $e (@{$self->{OICQ}->{EventQueue}}) {
		next unless ref($e) =~ /Client/;
		if ($e->seq eq $seq) {
			$event = $e;
			last;
		}
	}
	return 'Someone' unless defined $event;
	my ($id) = $event->{Data} =~ /^(\d+)/;
	return $id;
}

sub add_contact_1 {
	my ($self) = @_;
	my $plain = $self->{Data};
	my ($id, $reply) = split(/$Net::OICQ::RS/, $plain);
	$self->{Id} = $id;
	$self->{Reply} = $reply;
	my $srcid = $self->get_contact_id($self->seq);
	if ($reply =~ /^\d+$/) {
		if ($reply > 0) {
			$self->{Comment} = "$srcid requires authentication message.";
			return 0;
		} elsif ($reply == 0) {
			$self->{Comment} = "$srcid has accepted your request.";
			return 1;
		}
	}
	$self->{Comment} = "Unknown reply from add_contact_1 $srcid: $reply";
	return;
}

sub add_contact_2 {
}

# get_friends_list provided by Chen Peng

sub get_friends_list {
	my ($self) = @_;
	my $plain = $self->{Data};
	my $oicq = $self->{OICQ};
	my $flag = substr($plain, 0, 2);
	$self->{Flag} = unpack("H*", $flag);
	my $p = 2;
	my $len = length($plain);
	while ($p < $len) {
		my $fid = unpack('N', substr($plain, $p, 4));
		$p += 4; # one 0x00 to seperate
		my $face = $oicq->get_face(ord(substr($plain, $p+1, 1))); $p += 2;
		my $age = ord(substr($plain, $p, 1)); $p += 1;
		my $sex = ord(substr($plain, $p, 1)); $p += 1;
		my $name_len = ord(substr($plain, $p, 1)); $p += 1;
		my $nickname = substr($plain, $p, $name_len); $p += $name_len;
		my $unknown =  unpack("H*", substr($plain, $p, 4)); $p += 4;
		$oicq->{Info}->{$fid} = {} unless defined $oicq->{Info}->{$fid};
		my $info =  $oicq->{Info}->{$fid};
		$info->{Sex} = $sex;
		$info->{Age} = $age;
		$info->{Face} = $face;
		$info->{Nickname} = $nickname;
		$info->{Friend} = 1;
		$info->{Unknown} = $unknown;
	}
	if ($flag ne "\xff\xff") {
		$oicq->get_friends_list($flag);
	}
	return 1;
}

sub recv_friend_status {
	my ($self) = @_;
	my $plain = $self->{Data};
	my $oicq  = $self->{OICQ};
	my $srcid = unpack('N', substr($plain,  0, 4));
	my $addr = $oicq->show_address(substr($plain, 5, 6));
	$self->{Mode}  = ord(substr($plain, 12, 1));
	$self->{H13_33} = unpack("H*", substr($plain, 13, 20));
	$self->{DstId} = unpack('N', substr($plain, 35, 4));
	$self->{SrcId} = $srcid;
	$oicq->{Info}->{$srcid} = {} unless defined $oicq->{Info}->{$srcid};
	my $info = $oicq->{Info}->{$srcid};
	if ($addr =~ /[1-9]/) {
		$self->{Addr} = $addr;
		$info->{Addr} = $addr;
	}
	$info->{Mode} = $self->{Mode};
	return 1;
}

sub do_group {
	my ($self) = @_;
	my $plain = $self->{Data};
	my $oicq = $self->{OICQ};
	my ($sub_cmd, $reply) = unpack('H2H2', substr($plain, 0, 2));
	$self->{SubCmd} = $sub_cmd;
	$self->{Reply} = $reply;
	if ($reply ne '00'){
		$self->{Error} = substr($plain, 2);
		return;
	}
	if ($sub_cmd eq '06') { # search group
		my ($search_type, $int_gid, $ext_gid, $gtype, $x, $owner_id) =
			unpack('H2NNH2H8N', substr($plain, 2, 18));
		my $gname_len = ord(substr($plain, 30, 1));
		my $gname = substr($plain, 31, $gname_len);
		my $gauth_type = unpack('H*', substr($plain, 33+$gname_len, 1));
		my $gdesc_len = ord(substr($plain, 34+$gname_len, 1));
		my $gdesc = substr($plain, 35+$gname_len, $gdesc_len);
		$oicq->log_t("S_DO_GROUP $sub_cmd code $reply:\n", $oicq->hexdump($plain));
		$self->{GrpIntId} = $int_gid;
		$self->{GrpExtId} = $ext_gid;
		$self->{GrpOwner} = $owner_id;
		$self->{GrpName}  = $gname;
		$self->{GrpDesc}  = $gdesc;
		return 1;
	}
	if ($sub_cmd eq '04') { # group info
		my ($int_gid, $ext_gid, $gtype, $owner_id, $gauth_type) =
			unpack('NNH2NH2', substr($plain, 2, 14));
		my $cat = unpack("n",substr($plain, 18, 2));
		my $gname_len = ord(substr($plain, 24, 1));
		my $gname = substr($plain, 25, $gname_len);
		my $gnotice_len = ord(substr($plain, 27+$gname_len, 1));
		my $gnotice = substr($plain, 28+$gname_len, $gnotice_len);
		my $gdesc_len = ord(substr($plain, 28+$gname_len+$gnotice_len, 1));
		my $gdesc = substr($plain, 29+$gname_len+$gnotice_len, $gdesc_len);
		$self->{GrpIntId} = $int_gid;
		$self->{GrpName}  = $gname;
		$self->{GrpNotice} = $gnotice;
		$self->{GrpDesc}  = $gdesc;
		return 1;
	}
	if ($sub_cmd eq '0b') { # online group members
		$self->{GrpIntId} = unpack('N', substr($plain, 2, 4));
		my @online_members = length($plain) >= 11 ? unpack('N*', substr($plain, 7)) : ();
		$self->{OnlineMembers} = \@online_members;
		return 1;
	}
	$self->{Unknown} = unpack("H*", substr($plain, 2));
	return;
}

sub req_file_key {
	my ($self) = @_;
	my $plain = $self->{Data};
	my $oicq  = $self->{OICQ};
	unless (unpack('H4', $plain) eq '0400' and length($plain) > 18) {
		$oicq->log_t("Svr response to req_file_key:\n", $oicq->hexdump($plain));
		return;
	}
	my $file_key = substr($plain, 2, 16);
	$self->{FileKey} = $file_key;
	$oicq->log_t("Received file transfer key from server: $file_key");
}

1;
