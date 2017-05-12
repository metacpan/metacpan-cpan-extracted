package Net::OICQ;

# $Id: OICQ.pm,v 1.19 2007/06/16 12:35:08 tans Exp $

# Copyright (c) 2002 - 2007 Shufeng Tan.  All rights reserved.
# 
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)

use 5.008;
use strict;
use warnings;
use bytes;
use Carp;
use FileHandle;
use IO::Socket::INET;
use Digest::MD5;
use Encode;

use Crypt::OICQ qw(encrypt decrypt);
use Net::OICQ::ClientEvent;

our $VERSION = '1.6';

#################### Begin OICQ protocol data ######################

our $SERVER_DOMAIN = pack("H*", "74656e63656e742e636f6d");  # ;-)

# An OICQ session may use UDP or TCP.

# The first two bytes of a TCP packet are a short integer in network
# order (pack 'n'), which stores the data length including the leading
# two bytes.  Other than these two bytes, the format of TCP packets is
# identical to that of UDP packets.  The following description is
# for UDP packets only.

# A QQ data segment always begins with ASCII STX and ends with ASCII ETX

use constant STX => "\x02";
use constant ETX => "\x03";

# Bytes 0x01-0x02 seem to be client version

# These two bytes used to be fixed at 0x01 0x00 for packets from servers
# but they may use the same value as client, as of July 2006

# 0x06 0x2e for packets from GB client version 2000c build 630
# 0x07 0x2e for packets from En client version 2000c build 305
# 0x08 0x01 for packets from En client version 2000c build 630
# 0x09 0x09 for packets from GB client version 2000c build 1230b
# 0x0b 0x37 for packets from QQ 2003iii 0304
# 0x0e 0x2d for packets from GB client version 2005 sp1 V05.0.201.110
# 0x0f 0x5f for packets from GB client V06.0.200.410

our $CLIENT_VER = "\x0f\x5f"; #"\x0e\x2d";

# Bytes 0x03-0x04 indicate command

our %CmdCode = (
	logout             => "\0\x01",
	keep_alive         => "\0\x02",
	update_info        => "\0\x04",
	search_users       => "\0\x05",
	get_user_info      => "\0\x06",
	add_contact_1      => "\0\x09",
	del_contact        => "\0\x0a",
	add_contact_2      => "\0\x0b",
	set_mode           => "\0\x0d",
	ack_service_msg    => "\0\x12",
	send_msg           => "\0\x16",
	recv_msg           => "\0\x17",
	unknown_001a       => "\0\x1a",
	forbid_contact     => "\0\x1c",
	req_file_key       => "\0\x1d",  # provided by alexe
	cell_phone_1       => "\0\x21",  # provided by alexe
	login              => "\0\x22",
	get_friends_list   => "\0\x26",
	get_online_friends => "\0\x27",
	cell_phone_2       => "\0\x29",  # provided by alexe
	do_group           => "\0\x30",  # provided by alexe
	#login_request      => "\0\x62", # obsolete
	recv_service_msg   => "\0\x80",
	recv_friend_status => "\0\x81",
	login_request_1    => "\0\x91",
	login_request_2    => "\0\xba",
);

our %Cmd;
foreach my $cmd (keys %CmdCode) { $Cmd{$CmdCode{$cmd}} = $cmd }

our %GrpCmdCode = (
	get_info	=> "\x04",
	search		=> "\x06",
	online_members	=> "\x0b",
	member_info	=> "\x0c",
	grp_cmd_0x0f	=> "\x0f",
	grp_cmd_0x19	=> "\x19",
	send_msg	=> "\x1a",
	grp_cmd_0x36	=> "\x36",
);

our %GrpCmd;
foreach my $cmd (keys %GrpCmdCode) { $GrpCmd{$GrpCmdCode{$cmd}} = $cmd }

# Bytes 0x05-0x06 form a packet sequence number, a 16-bit integer

# Login modes
our %ConnectMode = (
	Normal    => "\x0a",
	Away      => "\x1e",
	Invisible => "\x28"
);

# System message code for 0x80 cmd
our %ServiceMsgCode = (
	'01' => 'User',
	'02' => 'ContactRequest',
	'06' => 'Broadcast'
);

# Separators
our $FS = "\x1e";   # Field separator
our $RS = "\x1f";   # Record separator

our @InfoHeader = qw(
	UserID Nickname Country Province PostCode Street Phone Age Sex Realname
	Email PagerCode PagerProvider PagerStationNum PagerNum PagerType
	Occupation Homepage Authorization unkn19 unkn20 Avatar
	MobilePhone MobileType Aboutme City unkn26 unkn27 unkn28 PublishMobile
	PublishContact School Horoscope Shengxiao BloodType unkn35 unkn36
);

our %Emoticon = (
	"\x41" => '¾ªÑÈ', "\x42" => 'Æ²×ì', "\x43" => 'É«', "\x44" => '·¢´ô', "\x45" => 'µÃÒâ',
	"\x46" => 'Á÷Àá', "\x47" => 'º¦Ðß', "\x48" => '±Õ×ì', "\x49" => 'Ë¯', "\x4a" => '´ó¿Þ',
	"\x4b" => 'ÞÏÞÎ', "\x4c" => '·¢Å­', "\x4d" => 'µ÷Æ¤', "\x4e" => 'ßÚÑÀ', "\x4f" => 'Î¢Ð¦',
	"\x73" => 'ÄÑ¹ý', "\x74" => '¿á', "\x75" => '·Çµä', "\x76" => '×¥¿ñ', "\x77" => 'ÍÂ',
	"\x8a" => '', "\x8b" => '', "\x8c" => '', "\x8d" => '', "\x8e" => '',
	"\x8f" => '', "\x78" => '', "\x79" => '', "\x7a" => '', "\x7b" => '',
	"\x90" => '', "\x91" => '', "\x92" => '', "\x93" => '', "\x94" => '',
	"\x95" => '', "\x96" => '', "\x97" => '', "\x98" => '', "\x99" => '',
	"\x59" => '', "\x5a" => '', "\x5c" => '', "\x58" => '', "\x57" => '', 
	"\x55" => '', "\x7c" => '', "\x7d" => '', "\x7e" => '', "\x7f" => '',
	"\x9a" => '', "\x9b" => '', "\x60" => '', "\x67" => '', "\x9c" => '',
	"\x9d" => '', "\x9e" => '', "\x5e" => '', "\x9f" => '', "\x89" => '',
	"\x80" => '', "\x81" => '', "\x82" => '', "\x62" => '', "\x63" => '',
	"\x64" => '', "\x65" => '', "\x66" => '', "\x83" => '', "\x68" => '',
	"\x84" => '', "\x85" => '', "\x86" => '', "\x87" => '', "\x6b" => '',
	"\x6e" => '', "\x6f" => '', "\x70" => '', "\x88" => '', "\xa0" => '',
	"\x50" => '', "\x51" => '', "\x52" => '', "\x53" => '', "\x54" => '',
	"\x56" => '', "\x5b" => '', "\x5d" => '', "\x5f" => '', "\x61" => '',
	"\x69" => 'ÏÂÓê', "\x6a" => '¶àÔÆ', "\x6c" => 'Ñ©ÈË', "\x6d" => 'ÐÇÐÇ', "\x71" => 'Å®',
	"\x72" => 'ÄÐ'
);

# Some constants for constructing client packets
my $PacketHead = STX . $CLIENT_VER;

my $ProxyConnect = "CONNECT %s HTTP/1.1\r\nAccept: */*\r\nContent-Type: text/html\r\nProxy-Connection: Keep-Alive\r\nContent-length: 0\r\n\r\n";

#################### End OICQ protocol data ########################

# Constructor

sub new {
	my ($class) = @_;
	my $homedir = exists($ENV{HOME}) ? $ENV{HOME} :
			(exists($ENV{HOMEPATH}) ? $ENV{HOMEPATH} : '.');
	my $dir = "$homedir/.oicq";
	if (-e $dir) {
		-d $dir or croak "$dir exists but is not a directory";
	} else {
		mkdir($dir) or croak "Failed to mkdir $dir: $!";
	}
	my $self = {
		Dir        => $dir,
		LastSvrAck => 0,
		Font	   => 'Tahoma',
		FontSize   => 12,
		FontColor  => '00a000',
		Debug      => 0  # 1 - trace packets, 2 - desect packets
	};
	my $logfile = "$dir/oicq.log";
	my $log = new FileHandle ">>$logfile";
	defined($log) or croak "Failed to open >>$logfile";
	$log->autoflush;
	$self->{LogFile} = $logfile;
	$self->{Log} = $log;
	return bless($self, $class);
}

# Methods that do not require connection to a server

sub set_user {
	my ($self, $id, $pw) = @_;

	$self->{Id} = $id;
	$self->{Passwd} = $pw;
	$self->{_Id} = pack('N', $id);
	$self->{PWKey} = Digest::MD5::md5(Digest::MD5::md5($pw));
	$self->{EventQueue} = [];
	$self->{EventQueueSize} = 50;
	$self->{SearchCount} = 0;
	$self->{LogChat}   = 1;
	$self->{Info}      = {};      # use id as hash key
	$self->{Away}      = 0;
	$self->{LastAutoReply} = {};  # use id as hash key
	$self->{AutoAwayTime} = "";

	my $userdir = "$self->{Dir}/$id";
	-e $userdir or mkdir($userdir);
	if (-d $userdir) {
		foreach ($self->get_saved_ids) { $self->get_nickname($_) };
		my $logfile = "$userdir/user.log";
		my $log = new FileHandle(">>$logfile");
		if (defined $log) {
			$self->log_t("Switch log to $logfile") if $self->{Debug};
			$self->{Log} = undef;
			$self->{LogFile} = $logfile;
			$self->{Log} = $log;
			$log->autoflush;
		} else {
			$self->log_t("Failed to open >>$logfile");
		}
	} else {
		$self->log_t("Failed to mkdir $userdir");
	}
}

# Methods for building OICQ packets

sub finalize_packet {
	use bytes;
	my ($self, $packet) = @_;
	return($packet) if $self->{UDP};
	return(pack('n', length($packet) + 2) . $packet);
}

# A TCP packet from server may contain multiple QQ data segment, sometimes with
# null segments in the beginning, the end, or between commands.
# get_data method returns a list of valid QQ data segments, each of
# which generates a server event.

sub get_data {
	my ($self, $packet) = @_;
	return () unless $packet;
	# do nothing to UDP packets
	return ($packet) if $self->{UDP};
	my $len = length($packet);
	if ($len < 10) {  # 2 leading bytes + 7 bytes of header + 1 byte of tail(0x03)
		$self->log_t("Discard short segment:\n", unpack("H*", $packet)) if $self->{Debug} > 8;
		return ();
	}
	my $len1 = unpack('n', substr($packet, 0, 2));
	return () if $len1 == 0;  # TCP QQ packets must declare length in the beginning
	if ($len1 <= $len) {
		if (substr($packet, 2, 1) eq STX and substr($packet, $len1-1, 1) eq ETX) {
			return(substr($packet, 2, $len1 - 2), get_data($self, substr($packet, $len1)));
		}
		$self->log_t("$len1 bytes discarded:\n", unpack("H*", substr($packet, 0, $len1))) if $self->{Debug} > 8;
		return get_data($self, substr($packet, $len1)) if $len > $len1;
		return ();
	}
	$self->log_t("Fragmented packet:\n", unpack("H*", $packet)) if $self->{Debug} > 8;
	return ();
}

# sub build_packet has been merged into sub send2svr

sub rand_str {
	my $len = pop;
	join('', map(pack("C", rand(0xff)), 1..$len));
}

sub build_login_request_packet {
	my ($self, $step) = @_;
	die "Invalid login request step: $step\n" unless $CmdCode{"login_request_$step"};
	my $randkey = rand_str(16);
	# Need to save it for decrypting server responses
	$self->{"RandKey$step"} = $randkey;
	my $data = $step == 1 ? "\0"x15 : "\1\0\5\0\0\0\0";
	my $seq = pack('n', rand(0xff));
	$self->{Seq} = unpack('n', $seq);
	my $packet = $PacketHead . $CmdCode{"login_request_$step"} . $seq . $self->{_Id} .
		$randkey . encrypt(undef, $data, $randkey) . ETX;
	$self->finalize_packet($packet);
}

sub build_login_packet {
	my ($self, $server_response) = @_;

	my $randkey = rand_str(16);
	$self->{RandKey} = $randkey;
	# No change in seq number
	my $data = encrypt(undef, "", $self->{PWKey}) . "\0"x19 .
		#pack('H*', '09f9cce1f7e8502203cd7731deabfcda') .
		pack('H*', '41d118ac147858f1d0814d7d7d7bd91f') .
		#pack('H*', '01') .
		pack('C', 0xc4) . #rand(0xff)) .
		$ConnectMode{$self->{ConnectMode}} . "\0"x25 .
		#pack('H*', '2447087cb1d3404cbda9037f36689e39') .
		pack('H*', 'd7e27d1ab27e6346a70c4c0c3bd53256') .
		#substr($server_response, 8, -1) .
		substr($server_response, 5) .
		#pack('H*', '0140011032a09700104fac17133afc7e8cfd1bd97d2613adc2') . 
		pack('H*', '01400175fda7bc00106b12f591b1d70bed46bbc3c23c663038') .
		"\0"x5 . "\x06" . "\0"x19 .
		pack('H*', '0299c281ae0010bb2673dcc29868b74cbc3f08cce01ea1') .
		#(pack('H*', '00')x297);
		"\0"x249;
	my $packet = $PacketHead . $CmdCode{'login'} . pack('n', $self->{Seq}) .
		$self->{_Id} . $randkey . encrypt(undef, $data, $randkey) . ETX;
	$self->finalize_packet($packet);
}

sub build_logout_packet {
	my ($self) = @_;
	my $packet = $PacketHead . $CmdCode{'logout'} . ("\xff" x 2) . $self->{_Id} .
		encrypt(undef, $self->{PWKey}, $self->{Key}) . ETX;
	$self->finalize_packet($packet);
}

# Methods for logging and output

sub log {
	my $self = shift;
	my $log = $self->{Log};
	my $mesg = "@_";
	#Encode::from_to($mesg, 'euc-cn', 'utf8');
	print $log $mesg;
}

sub logf {
	my $self = shift;
	my $log = $self->{Log};
	my $mesg = "@_";
	#Encode::from_to($mesg, 'euc-cn', 'utf8');
	printf $log $mesg;
}

sub log_t {
	my ($self, @msg) = @_;
	my $log = $self->{Log};
	my $mesg = "@msg\n";
	#Encode::from_to($mesg, 'euc-cn', 'utf8');
	print $log substr(localtime, 4, 16), $mesg;
}

sub hexdump {
	my $str = pop;
	return unless defined $str;
	my $res = "";
	my $len = length($str);
	for (my $i = 0; $i < $len; $i += 16) {
		my $s = substr($str, $i, 16);
		my $hex = unpack('H*', $s);
		#$s =~ s/[\x00-\x1f\x80-\x8f]/./g;   # 0x00-0x1f will screw up terminal
		$hex =~ s/(\w\w)/$1 /g;
		$res .= $hex . "\n"; # sprintf("%-48s    %s\n", $hex, $s);
	}
	$str =~ s/[\x00-\x1f]/./g;
	return $res . $str . "\n";
}

sub dump_substr {
	my ($self, $data, $tmpl, $prefix, $begin, $len) = @_;
	my ($str, $end);
	if (defined($len)) {
		$str = substr($data, $begin, $len);
		$end = ($begin+$len < length($data)) ? $begin+$len-1 : length($data)-1;
	} else {
		$str = substr($data, $begin);
		$end = length($data)-1;
	}
	$self->logf("0x%02x-0x%02x %s: ", $begin, $end, $prefix);
	if ($tmpl =~ /\w/) {
		if ($tmpl eq 'H*') {
			$self->log("\n", $self->hexdump($str));
		} else {
			$self->log(unpack($tmpl, $str), "\n");
		}
	} else {
		$self->log("$str\n");
	}
}

sub desect {
	my $self = shift;
	return unless $self->{Debug} > 1;
	my $data = shift;
	foreach my $arg (@_) {
		$self->dump_substr($data, @{$arg});
	}
	return;
}

sub show_address {
	my ($self, $data) = @_;
	my $ip = join('.', map(ord($_), split('', substr($data, 0, 4))));
	return $ip unless length($data) >= 6;
	my $port = unpack('n', substr($data, 4, 2));
	return "$ip:$port";
}

sub remove_saved_id {
	my ($self, $id) = @_;
	my $file = "$self->{Dir}/$self->{Id}/$id.dat";
	if (-e $file) {
		unlink($file);
		return 0 if -e $file;
		return 1;
	} else {
		return 0;
	}
}

sub get_saved_ids {
	my ($self) = @_;
	my $dir = "$self->{Dir}/$self->{Id}";
	my @ids = ();
	if (opendir(DIR, $dir)) {
		while(my $f = readdir(DIR)) {
			next unless $f =~ /^(\d+)\.dat$/;
			push @ids, $1;
		}
		closedir(DIR);
	}
	return @ids;
}

sub get_face {
	my $num = pop;
	return $num unless $num =~ /^\d+$/;
	sprintf('%d-%d', 1 + $num/3, 1 + $num % 3);
}

sub toggle_autoreply {
	my ($self) = @_;
	if ($self->{Away}) {
		$self->{Away} = 0;
		return "off";
	} else {
		$self->{Away} = 1;
		return "on";
	}
}

# Nickname can be updated by get_friends_list or get_user_info

sub get_nickname {
	my ($self, $id) = @_;
	if (defined $self->{Info}->{$id}) {
		if (defined $self->{Info}->{$id}->{Nickname}) {
			return $self->{Info}->{$id}->{Nickname};
		}
	} else {
		$self->{Info}->{$id} = {};
	}
	my $infofile = "$self->{Dir}/$self->{Id}/$id.dat";
	my $nick = "";
	if (open(INFO, $infofile)) {
		while(my $line = <INFO>) {
			if ($line =~ /^Nickname +=> *'(.*)'/) {
				$nick = $1;
				last;
			}
		}
		close(INFO);
	}
	$self->{Info}->{$id}->{Nickname} = $nick;
	return $nick;
}

sub get_servers {
	my @servers;
	if (exists $ENV{OICQ_SVR} and $ENV{OICQ_SVR} =~ /\w+/) {
		my $svr = $ENV{OICQ_SVR};
		$svr =~ s/^\W+//;
		$svr =~ s/\W+$//;
		@servers = split(/[^\w\.]+/, $svr);
		return @servers if @servers;
	}

	my $type = pop;
	if ($type =~ /udp/i) {
		map {'sz'. $_ . '.' . $SERVER_DOMAIN} (2 .. 9, '');
	} else {
		map {'tcpconn' . $_ . '.' . $SERVER_DOMAIN} (6, 5, 4, 3, 2, '');
	}
}

sub tcp_connect {
	my ($self, $server, $proxy) = @_;
	my ($svr_ip, $svr_port);
	if ($server =~ /^(\S+):(\d+)$/) {
		($svr_ip, $svr_port) = ($1, $2);
	} else {
		$svr_ip = $server;
		$svr_port = 443;
	}
	my $socket;
	$proxy = $ENV{OICQ_PROXY} unless defined $proxy;
	if ($proxy) {
		my ($proxy_ip, $proxy_port);
		if ($proxy =~ /:/) {
			($proxy_ip, $proxy_port) = split(/:/, $proxy);
		} else {
			$proxy_ip = $proxy;
			$proxy_port = 80;
		}
		$socket = IO::Socket::INET->new(
			Proto => 'tcp', PeerAddr => $proxy_ip, PeerPort => $proxy_port
		);
		unless(defined $socket) {
			$self->mesg("socket error: $@");
			return;
		}
		$self->{Socket} = $socket;
		$socket->send(sprintf $ProxyConnect, "$svr_ip:$svr_port");
		my $resp = $self->timed_recv(0x4000, 10);
		if (defined $resp && $resp =~ m|HTTP/.+ 200 Connection established|) {
			$self->mesg("via proxy $proxy_ip:$proxy_port ");
			$self->{Proxy} = "$proxy_ip:$proxy_port";
			$self->{SvrIP} = $svr_ip;
			$self->{SvrPort} = $svr_port;
			$self->{Socket} = $socket;
			$self->{UDP} = 0;
			return $socket;
		}
		$resp = "" unless defined $resp;
		$self->mesg("failed to connect to proxy $proxy_ip:$proxy_port\n$resp\n");
		return;
	} else {
		$socket = IO::Socket::INET->new(
			Proto => 'tcp', PeerAddr => $svr_ip, PeerPort => $svr_port
		);
		unless(defined $socket) {
			$self->mesg("socket error: $@");
			return;
		}
		$self->{SvrIP} = $svr_ip;
		$self->{SvrPort} = $svr_port;
		$self->{Socket} = $socket;
		$self->{UDP} = 0;
		return $socket;
	}
}

sub timed_recv {
	my ($self, $length, $timeout) = @_;
	my $socket = $self->{Socket};
	my $timeout_msg = "tImEoUt\n";
	my $res;
	local $SIG{ALRM} = sub { die $timeout_msg };
	alarm($timeout);
	eval { $socket->recv($res, $length, 0); alarm(0) };
	if ($@ eq $timeout_msg) {
		return;
	}
	return $res;
}

sub udp_connect {
	my ($self, $server) = @_;
	croak "Server IP not provided\n" unless defined($server);
	my $port = 8000;

	my $socket = IO::Socket::INET->new(
			Proto => 'udp', PeerAddr => $server, PeerPort => $port
	);
	unless(defined $socket) {
		$self->mesg("socket error: $@");
		return;
	}
	$self->{SvrIP}   = $server;
	$self->{SvrPort} = $port;
	$self->{Socket}  = $socket;
	$self->{UDP}     = 1;
	return $socket;
}

sub connect {
	my $self = shift;
	my $proto = shift;
	($proto eq 'udp') ? $self->udp_connect(@_) : $self->tcp_connect(@_);
}

sub login {
	my ($self, $id, $pw, $mode, $proto, $proxy) = @_;
	$self->set_user($id, $pw);
	$self->{Key} = "";
	$| = 1;

	if (defined $mode && exists $ConnectMode{$mode}) {
		$self->log_t("login as $id in $mode mode");
		$self->{ConnectMode} = $mode;
	} else {
		$self->log_t("login as $id, default to invisible mode");
		$self->{ConnectMode} = 'Invisible';
	}
	# Default to tcp connection
	$proto = 'tcp' unless defined($proto) && $proto eq 'udp';
	my @servers = $self->get_servers($proto);
	my $login_packet;
   SVR: foreach my $svr (@servers) {
		$self->mesg("Connecting to $proto server $svr...");
		my $socket = $self->connect($proto, $svr, $proxy);
		next SVR unless defined $socket;
		$self->mesg("socket created...") if $self->{Debug};

	   	unless ($login_packet) {
			my $token = $self->get_login_token($svr, $proto, $proxy);
			next SVR unless $token;
			$login_packet = $self->build_login_packet($token);
		}
		my $plain = $self->decrypt_login_response($login_packet);
		unless(defined $plain) {
			$login_packet = undef;
			next SVR;
		}
		$self->mesg("decrypted login resp: ", unpack("H*", $plain), "\n") if $self->{Debug};
		my $login = ord($plain);
		if ($login == 0) { # login successfull
			$self->{Key} = substr($plain, 1, 0x10);
			$self->{Addr} = $self->show_address(substr($plain, 0x15, 6));
			$self->{LoginTime} = unpack('N', substr($plain, 0x21, 4));
			$self->{Addr2} = $self->show_address(substr($plain, 0x7b, 4));
			$self->{LoginTime2} = unpack('N', substr($plain, 0x7f, 4));
			$self->mesg("ok.\n");
			last SVR;
		} elsif ($login == 1) { # redirect to another server
			$svr = $self->show_address(substr($plain, 5, 6));
			($self->{SvrIP}, $self->{SvrPort}) = split(/:/, $svr);
			$self->{Socket} = undef;
			$self->log_t("redirected to server $svr");
			$self->mesg(" redirected.\n");
			redo SVR;
		} elsif ($login == 9 or $login == 5) { # wrong password
			$self->mesg("$plain\nError code $login\n");
			last SVR;
		} elsif ($login == 10) { # redirect to another server
			$svr = $self->show_address(substr($plain, -4));
			$self->mesg("redirected to server $svr (code $login).\n");
			$self->{SvrIP} = $svr;
			$self->{Socket} = undef;
			$socket = undef;
			redo SVR;
		} else {
			my $h = unpack("H*", $plain);
			$self->mesg("failed with error code $login\n$h\n");
			last SVR;
		}
	}

	return 0 unless $self->{Key};

	# Make sure we logout when control-C is pressed
	$SIG{INT} = sub { $self->logout; exit 1 };
	# Prepare LogoutPacket for logout
	$self->{LogoutPacket} = $self->build_logout_packet;
	$self->{LastKeepaliveTime} = time;

	return 1;
}

sub get_login_token {
	my ($self) = @_;
	my $socket = $self->{Socket};
	return unless defined $socket;
	$self->mesg("socket created...") if $self->{Debug};
	my ($login_req, $resp);
	foreach my $step (2) {
		$login_req = $self->build_login_request_packet($step);
		$socket->send($login_req);
		$self->mesg("waiting for token $step...") if $self->{Debug};
		$resp = $self->timed_recv(1024, 5);
		if (defined $resp) {
			$self->mesg("received...") if $self->{Debug};
		} else {
			$self->mesg("timed out.\n");
			return;
		}
	}
	#foreach (1 .. 8) {
	#	$socket->send($login_req);
	#}
	my $token;
	foreach my $r ($self->get_data($resp)) {
		next unless substr($r, 3, 2) eq $CmdCode{login_request_2};
		eval { $token = decrypt(undef, substr($r, 7, -1), $self->{RandKey2}) };
		$self->mesg("token:", unpack("H*", $token)) if $self->{Debug};
		return($token) if $token;
	}

	$self->mesg("unexpected server response to login request:\n",
		unpack('H*', $resp), "\n$resp\n");
	return;
}

sub decrypt_login_response {
	my ($self, $login_packet) = @_;
	$self->{Socket}->send($login_packet);
	$self->mesg("login packet sent ...");
	my $data;
  RECV: while (1) {
		my $resp = $self->timed_recv(4096, 5);
		unless($resp) {
			$self->mesg(" no response.\n");
			return;
		}
		foreach my $d ($self->get_data($resp)) {
			$self->mesg("\nServer response:", unpack("H*", $d), "\n") if $self->{Debug};
			if (substr($d, 3, 2) eq "\x00\x22") {
				$data = $d;
				last RECV;
			}
		}
	}
	$self->{LastSvrAck} = time;
	#my ($data) = $self->get_data($resp);
	#return unless defined $data;
	my $crypt = substr($data, 7, -1);
	my $plain;
	$self->mesg("received ", length($crypt), " bytes...") if $self->{Debug};
	my @keys = length($crypt) == 32 ? qw(RandKey PWKey) : qw(PWKey RandKey);
	foreach my $key (@keys) {
		eval { $plain = decrypt(undef, $crypt, $self->{$key}) };
		if (defined $plain) {
			$self->mesg("decrypted with $key\n") if $self->{Debug};
			return $plain;
		}
		$self->mesg("Failed to decrypt login response: $@") if $@ && $self->{Debug};
	}
	return undef;
}

sub mesg {
	my ($self, @mesg) = @_;
	my $mesg = "@mesg";
	if (exists($ENV{LANG}) and $ENV{LANG} =~ /UTF-8/) {
		Encode::from_to($mesg, 'euc-cn', 'utf8');
	}
	print $mesg;
}

# send2svr may take command Seq num as an optional argument
# it returns a Net::OICQ::ClientEvent object if the packet is sent

sub send2svr {
	my ($self, $cmd, $data, $seq) = @_;
	croak "send2svr error: bad command: $cmd" unless exists $CmdCode{$cmd};
	unless(defined $seq) {
		$seq = pack('n', ++$self->{Seq});
	}
	my $header = $PacketHead . $CmdCode{$cmd} . $seq . $self->{_Id};
	my $crypt = encrypt(undef, $data, $self->{Key});
	my $packet = $self->finalize_packet("$header$crypt" . ETX);
	if ($self->{Socket}->send($packet)) {
		return(new Net::OICQ::ClientEvent($header, $data, $self));
	}
	return undef;
}

# get_friends_list provided by Chen Peng

sub get_friends_list {
	my ($self, $flag) = @_;
	defined $flag or $flag = pack('H4', '0000');
	$self->send2svr('get_friends_list', $flag);
}

sub get_online_friends {
	my ($self) = @_;
	$self->send2svr('get_online_friends', pack('H*', '0200000000'));
}

sub set_mode {
	my ($self, $mode_code) = @_;
	$self->send2svr('set_mode', $mode_code);
}

sub get_user_info {
	my ($self, $id) = @_;
	$self->send2svr('get_user_info', $id);
}

sub update_info {
	my ($self, $hashref) = @_;
	my $info = $self->{MyInfo};
	return unless defined $hashref and defined $info;
	my %new_info;
	# Use all upper-case letters for keys
	foreach my $k (keys %$hashref) {
	$new_info{uc($k)} = $hashref->{$k};
	}
	my @update;
	for (my $i = 1; $i < $#InfoHeader; $i++) {
		my $attr = uc($InfoHeader[$i]);
		push(@update, defined($new_info{$attr}) ? $new_info{$attr} : $info->[$i]);
	}
	$self->send2svr('update_info', join($RS, "", "", @update));
}

sub set_passwd {
	my ($self, $newpw) = @_;
	return unless defined $self->{MyInfo};
	my @info = @{$self->{MyInfo}};
	pop @info; shift @info;
	$self->send2svr('update_info', join($RS, $self->{Passwd}, $newpw, @info));
}

sub accept_contact {
	my ($self, $id) = @_;
	$self->send2svr('add_contact_2', $id.$RS."0");
}

sub reject_contact {
	my ($self, $id) = @_;
	$self->send2svr('add_contact_2', $id.$RS."1");
}

sub add_contact {
	my ($self, $id) = @_;
	$self->send2svr('add_contact_1', "$id");
}

sub add_contact_2 {
	my ($self, $id, $msg) = @_;
	$self->send2svr('add_contact_2', "$id$RS"."2$RS$msg");
}

sub del_contact {
	my ($self, $id) = @_;
	$self->send2svr('del_contact', "$id");
}

sub forbid_contact {
	my ($self, $id) = @_;
	$self->send2svr('forbid_contact', "$id");
}

sub msg_tail {
	my ($self) = @_;
	my $font_name = $self->{Font};
	# Let's have fun with font size and color
	my $font_size  = $self->{FontSize};
	my $font_color = $self->{FontColor};
	if ($font_size =~ /^\d+$/) {
		$font_size = chr($font_size);
	} else {
		$font_size = chr(8+rand(14));
	}
	if ($font_color =~ /^[\da-f]{6}$/) {
		$font_color = pack("H*", $font_color);
	} else {
		$font_color = chr(rand(0xff)).chr(rand(0xff)).chr(rand(0xff));
	}
	my $msg_tail = " \0$font_size$font_color\0\x86\x02$font_name";
	# Don't know what would happen if font_name is very looooong.  Don't care either.
	return $msg_tail . chr(length($msg_tail));
}

# send_msg is also used for auto-reply
# I don't think this is a bug, it is a feature.
sub send_msg {
	my ($self, $dstid, $msg) = @_;
	use bytes;
	my $nickname = $self->get_nickname($dstid);
	if ($dstid =~ /^20/ and $nickname eq "\xc8\xba") {
		# Group message
		return $self->send_group_msg($dstid, $msg);
	}
	$self->log_t("Sent message to $dstid:\n", $msg) if $self->{LogChat};
	my $dstid_ = pack('N', $dstid);
	my $head = $self->{_Id} . $dstid_ . $CLIENT_VER . $self->{_Id} . $dstid_ .
			Digest::MD5::md5($dstid_ . $self->{Key}) . "\0\x0b";
	my @trunks = $self->split_gb_msg($msg);
	my $last_trunk = pop(@trunks);
	my $msg_seq = 0x57 + rand(0xa8);
	my $time = pack('N', time);
	foreach my $trunk (@trunks) {
		my $data = $head . pack('n', ++$msg_seq) . $time .
			"\0\x3f\0\0\0\1\1\0" . chr(rand(0xfd)) . "\0\1" . $trunk;
		$self->send2svr('send_msg', $data);
		sleep(1);
	}
	my $data = $head . pack('n', ++$msg_seq) . $time .
			"\0\x3f\0\0\0\1\1\0" . chr(rand(0xfd)) . "\0\1" .
			$last_trunk . $self->msg_tail;
	$self->send2svr('send_msg', $data);
}

# Server will not send message longer than 601 bytes

sub split_gb_msg {
	my ($self, $msg) = @_;
	my $len = length($msg);
	my $max_len = 601;
	return ($msg) if $len <= $max_len;
	my $msg0 = substr($msg, 0, $max_len);
	# here is my idea of splitting a long messages while avoiding breaking up
	# any GB character
	# First, count the non GB characters in the first 601 characters
	my $non_gb_count = $msg0 =~ tr/\x00-\xa0/\x00-\xa0/;
	if ($non_gb_count % 2) {
		# if there are an odd number of non GB characters,
		# it's ok to break at position 601
		return ($msg0, $self->split_gb_msg(substr($msg, $max_len)));
	} else {
		$max_len--;
		return (substr($msg, 0, $max_len), $self->split_gb_msg(substr($msg, $max_len)));
	}
}

sub ack_msg {
	my ($self, $seq, $plain) = @_;
	$plain = substr($plain, 0, 16);
	my $event = $self->send2svr('recv_msg', $plain, $seq);
	if ($self->{UDP}) {
		foreach (1..2) {
			$self->send2svr('recv_msg', $plain, $seq);
		}
	}
	return $event;
}

sub ack_service_msg {
	my ($self, $code, $srcid, $seq) = @_;
	$self->send2svr('ack_service_msg', "$code$FS$srcid$FS$seq");
}

sub keepalive {
	my ($self) = @_;
	$self->{LastKeepaliveTime} = time;
	$self->send2svr('keep_alive', $self->{Id});
}

sub search_user {
	my ($self, $id) = @_;
	$self->send2svr('search_users', join($RS, '0', $id, '-','-','0'));
}

sub list_online_users {
	my ($self, $num) = @_;
	defined $num or $num = 1;
	my $begin = $self->{SearchCount};
	$self->{SearchCount} += $num; 
	my $end = $self->{SearchCount} -1;
	foreach my $p ($begin .. $end) {
		$self->send2svr('search_users', "1".$RS."$p");
	}
}

sub request_file_key {
	my ($self, $hex_code) = @_;
	$self->send2svr('req_file_key', pack("H*", $hex_code));
}

sub do_group {
	my ($self, $group_cmd, $group_id, $what) = @_;
	my $data = $GrpCmdCode{$group_cmd};
	$data .= pack('H2', '01') if $group_cmd eq 'search';
	$data .= pack('N', $group_id) . $what;
	$self->send2svr('do_group', $data);
}

# Group functions are provided by alexe

sub send_group_msg {
	my ($self, $group_id, @msg) = @_;
	my $mesg = "@msg";
	$self->log_t("Sent message to Group $group_id:\n", $mesg) if $self->{LogChat};
	my $group_int_id = $self->group_int_id($group_id);
	my @trunks = $self->split_gb_msg($mesg);
	my $last_trunk = pop(@trunks);
	foreach my $trunk (@trunks) {
		my $data = "\0\1\1\0\x39\xe8\0\0\0\0$trunk";
		$data = pack('n', length($data)) . $data;
		$self->do_group('send_msg', $group_int_id, $data);
		sleep(1);
	}
	my $data = "\0\1\1\0\x39\xe8\0\0\0\0$last_trunk" . $self->msg_tail;
	$data = pack('n', length($data)) . $data;
	$self->do_group('send_msg', $group_int_id, $data);
}

sub get_group_info {
	my ($self, $group_id) = @_;
	$self->do_group('get_info', $self->group_int_id($group_id), "");
}

sub search_group {
	my($self, $group_id) = @_;
	$self->do_group('search', $group_id, "");
}

sub group_online_members {
	my ($self, $group_id) = @_;
	$self->do_group('online_members', $self->group_int_id($group_id), "");
}

sub group_int_id {
	my ($self, $group_id) = @_;
	$group_id += 202000000 if $group_id < 202000000;
	return $group_id;
}

sub logout {
	my $self = shift;
	defined($self->{LogoutPacket}) && $self->{LogoutPacket} || return;
	my $packet = $self->{LogoutPacket};
	foreach (1..3) {
		$self->{Socket}->send($packet);
	}
}

1;

__END__

=head1 NAME

Net::OICQ - Perl extension for QQ instant messaging protocol

=head1 SYNOPSIS

  use Net::OICQ;
  $oicq = new Net::OICQ;
  $oicq->login($qqid, $passwd, "Invisible", "tcp", $proxy);
  # or
  # $oicq->login($qqid, $passwd, "Invisible", "udp");
  $oicq->send_msg("52482796", "Hello");
  my $resp = $oicq->timed_recv(1024, 5);
  print unpack("H*", $resp), "\n";
  $oicq->logout;

=head1 DESCRIPTION

This module implements an object-oriented interface to QQ instant messaging protocol.
It requires two Perl modules, Digest::MD5 and Crypt::OICQ.  Net::OICQ class provides
methods to connect to a QQ server, and send commands to other QQ users via the server.

Net::OICQ::ServerEvent class provides methods to parse messages received from the server.

Net::OICQ::ClientEvent class provides methods to process messages sent from a client.

Net::OICQ::TextConsole class is an example of using the above classes for a command-line
interface.

=head1 CLASSES

=head2 Net::OICQ

Constructor:

	$oicq = new Net::OICQ;

Methods:

	$oicq->login($qq_id, $qq_passwd, $connect_mode[, $tcp_or_udp[, $http_proxy]]);

	$oicq->send2svr($command, $data[, $seq]);  # $seq is optional

	$oicq->logout;


=head2 Net::OICQ::ServerEvent

Constructor:

	$s_event = new Net::OICQ::ServerEvent $data, $oicq;

Methods:

	Net::OICQ::ServerEvent is a subclass of Net::OICQ::Event and inherits all methods of
	Net::OICQ::Event.  Net::OICQ::ServerEvent has a method for each QQ command supported
	by Net::OICQ module.

=head2 Net::OICQ::ClientEvent

Constructor:

	$event = new Net::OICQ::ClientEvent $data, $oicq;

=head2 Net::OICQ::Event

This is the super class for Net::OICQ::ServerEvent and Net::OICQ::ClientEvent.
It does not have a constructor.

Methods:

	client_ver, cmdcode, seq, cmd, process, parse and dump


=head1 EXPORT

None by default.

=head1 AUTHOR

Shufeng Tan <perloicq@yahoo.com>

=head1 SEE ALSO

L<perl>.

=cut
