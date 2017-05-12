package Net::Lite::FTP;


use 5.006000;
use strict;
use warnings;
use IO::Handle;
#use IO::Compress::Deflate qw(deflate $DeflateError);
#use IO::Uncompress::Inflate qw(inflate $InflateError);
use Compress::Raw::Zlib;
use Errno;
use Socket qw( SOCK_DGRAM SOCK_STREAM SOCK_RAW PF_INET SOL_SOCKET IPPROTO_IP SO_ERROR IPPROTO_IP IP_TOS IP_TTL
               inet_aton sockaddr_in  SO_SNDTIMEO SO_RCVTIMEO SO_KEEPALIVE);


require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Lite::FTP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

			) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

		);

our $VERSION = '0.84';
# Preloaded methods go here.
# Autoload methods go after =cut, and are processed by the autosplit program.
use constant BUFSIZE => 4096;
BEGIN {
	use Net::SSLeay::Handle qw/shutdown/;
# You only need this if your FTP server requires client certs:
#Net::SSLeay::Handle::_set_cert("/home/eyck/my.pem"); 
#Net::SSLeay::Handle::_set_key("/home/eyck/my.pem");
# but if you want this, you need to patch your Net::SSLeay, 
};

sub new($$) {
	my $class=shift;
	my $self={};
	bless $self,$class;
#                            $self->{'DBHandle'}=$dbh;
	$self->{"CreationTime"}=time;
	$self->{"Connected"}=0;
	$self->{"EncryptData"}=1;
	$self->{"Encrypt"}=1;
	$self->{"Debug"}=0;
	$self->{"ErrMSG"}=undef;
	#$self->{"ForcePASSVIP"}=undef;
	$self->{"GetUpdateCallback"}  = undef;
	$self->{"GetDoneCallback"}    = undef;
	$self->{"PutUpdateCallback"}  = undef;
	$self->{"PutDoneCallback"}    = undef;
	$self->{"CompressionLevel"}=1;
	$self->{"CompressionWindowBits"}=8;
	$self->{"CompressionBufsize"}=8192;
	$self->{"CompressionStrategy"}=4;
#define Z_FILTERED            1
#define Z_HUFFMAN_ONLY        2
#define Z_RLE                 3
#define Z_FIXED               4
#define Z_DEFAULT_STRATEGY    0
	return $self;
};

sub user($$) {
	my ($self,$user)=@_;
	$self->command("USER $user");
}
sub pass($$) {
	my ($self,$pass)=@_;
	$self->command("PASS $pass");
}
sub login($$$) {
	my ($self,$user,$pass)=@_;
	$self->command("USER $user");
	$self->command("PASS $pass");
}

sub cwd ($$) {
	my ($self,$data)=@_;
	$self->command("CWD $data");
}
sub mkdir ($$) {
	my ($self,$data)=@_;
	$self->command("MKD $data");
}
sub rmdir ($$) {
	my ($self,$data)=@_;
	$self->command("RMD $data");
}

sub bin ($) {
	my ($self)=@_;
	$self->command("TYPE I");
}
sub ascii ($) {
	my ($self)=@_;
	$self->command("TYPE A");
}

sub size ($$) {
	my ($self,$filename)=@_;
	my $size=$self->command("SIZE $filename");chop $size if defined($size);
	return $size;
}
sub cdup ($$) {
	my ($self,$data)=@_;
	$self->command("CDUP");
}
sub dele {
	my ($self,$pathname)=@_;
	return undef unless defined($pathname);
	$self->command("DELE $pathname");
}
sub rm {dele(@_);};
sub delete {dele(@_);};
sub del { shift->del(@_) };

sub rawmessage ($) {
	my ($self)=@_;
	return $self->{'FTPRAWMSG'};
};
sub message ($) {
	my ($self)=@_;
	return $self->{'FTPMSG'};
};
sub msgcode ($) {
	my ($self)=@_;
	return $self->{'FTPCODE'};
};

sub readln {
        my ($sock)=@_;
        my ($data,$ln);
        if (sysread($sock,$data,BUFSIZE)) {
                $ln=$data;
                while ($data!~/\n/) {
                        if (sysread($sock,$data,BUFSIZE)) {
                                #print "OPEN..Received: {$data}\n";# if $self->{Debug};
                                $ln.=$data;
                        };
                };
        };
        return $ln;
};

#sub SOL_IP { 0; };
#sub IP_TOS { 1; };

sub open($$$) {
	my ($self,$host,$port)=@_;
	my ($data);
	my $sock;
	$sock = Net::SSLeay::Handle->make_socket($host, $port);
	$self->{'Sock'}=$sock;
	$self->{'Host'}=$host;
	$self->{'Port'}=$port;
	#tmp
	
	#setsockopt($sock,&SOL_SOCKET,&SO_KEEPALIVE,undef,undef) || warn "setsockopt: $!";
	setsockopt($sock, SOL_SOCKET, SO_SNDTIMEO, pack('L!L!', 15, 0) ) or warn "setsockopt SNDTIMEO unset: ".$!;  
	setsockopt($sock, SOL_SOCKET, SO_RCVTIMEO, pack('L!L!', 15, 0) ) or warn "setsockopt RCVTIMEO unset: ".$!;
	setsockopt($sock, SOL_SOCKET, SO_KEEPALIVE, 1 ) or warn "setsockopt KEEPALIVE unset: ".$!;  
	#setsockopt($sock, SOL_SOCKET, IP_TOS, IPTOS_LOWDELAY ) or die "setsockopt".$!;  
	#/usr/share/perl/5.8.4/Net/Ping.pm:      setsockopt($self->{"fh"}, SOL_IP, IP_TOS(), pack("I*", $self->{'tos'}))
	#setsockopt($sock, SOL_IP, IP_TOS(), pack("I*",0x10 ));
	#LOWLATENCY
	setsockopt($sock, IPPROTO_IP, IP_TOS, pack("I*", 0x10))
		or warn "error configuring tos LOW LATENCY to $self->{'fh'} $!";


	#/usr/include/linux/ip.h:#define IPTOS_LOWDELAY          0x10
	##define IPTOS_THROUGHPUT        0x08
	#define	IPTOS_MINCOST		0x02
	#/usr/share/perl/5.8.4/Net/Ping.pm:      setsockopt($self->{"fh"}, SOL_IP, IP_TOS(), pack("I*", $self->{'tos'}))
	#end tmp 2008-11-04

	#FTPS EXPLICIT:
	if ($self->{'FTPS'}) {
		#{tie(*S, "Net::SSLeay::Handle", $sock);$sock = \*S;};
		# Unique glob?
		{my $io=new IO::Handle;	tie(*$io, "Net::SSLeay::Handle", $sock);$sock = \*$io;};
	}



	if ($data=readln($sock)) {
		print STDERR "OPEN.Received: $data" if $self->{Debug};
		$data=$self->responserest($data);
		print STDERR "OPEN..Received: $data" if $self->{Debug};
	}

	if ($self->{'Encrypt'} && (! $self->{'FTPS'} )) {
		$data="AUTH TLS\r\n";
		syswrite($sock,$data);
		if ($data=readln($sock)) {
			print STDERR "Received: $data" if $self->{Debug};
		}
	}

	if ($self->{'Integrity'}) {
		$self->command("INTEGRITY H");# TODO
	};

	if ($self->{'Compress'}) {
		$self->command("MODE Z");# TODO
	};
	$self->{'RAWSock'}=$sock;

	if ($self->{'Compress'}) {
		# IO::Compress::Deflate
		# IO::Uncompress::Inflate
	};

	if ($self->{'Encrypt'} && (! $self->{'FTPS'} )) {
		#{tie(*S, "Net::SSLeay::Handle", $sock);$sock = \*S;};
		# Unique glob?
		{my $io=new IO::Handle;	tie(*$io, "Net::SSLeay::Handle", $sock);$sock = \*$io;};
	}

	$self->{'Sock'}=$sock;
	{select($sock);$|=1;select(STDOUT);};#unbuffer socket

	$self->setup_protection();

# 
	return 1;
}

sub quit {
	my ($self)=@_;
	return $self->command("QUIT");
}
sub noop {
	my ($self)=@_;
	return $self->command("NOOP");
}
sub rename ($$$) {
	my ($self,$from,$to)=@_;
#"RNFR plik1"
#"RNTO plik2"
	if ($self->command("RNFR $from")) {
	return $self->command("RNTO $to");
	} else {return 0;};
};
sub mdtm ($$) {
	my ($self,$file)=@_;
	return $self->command("MDTM $file");
};

sub command ($$){
	my ($self,$data)=@_;
	print STDERR "Sending: ",$data."\n" if $self->{Debug};
	my $sock=$self->{'Sock'};
#	print $sock $data."\r\n";
 	syswrite( $sock ,$data."\r\n");
	return $self->response();
}

sub response ($) {
	my ($self)=@_;
	my $sock=$self->{'Sock'};
	my ($read,$resp,$code,$cont);
	my $start=time;
	$read=($resp=<$sock>);#, redo if (Errno::EAGAIN && (!defined($read)));
         #my $recvbytes=$sock->recv($read,1024);#, redo if Errno::EAGAIN;
	
	#TODO skip this, if RAWSock is disconnected... otherwise there's no sense in waiting for data..

	while (!defined($read) && Errno::EAGAIN && (time-$start<190)) {
		$read=($resp=<$sock>);
		#, redo until timeout or sth
	}

	if (!defined($read)) {
		warn "EAGAIN again 190s! $!" if Errno::EAGAIN;
		warn "Damn! undefined response (err:$!) {H: ".$self->{'Host'}." P:".$self->{'Port'}."}\n";# unless defined($read);
		$self->{'FTPCODE'}=undef;
		$self->{'FTPMSG'}=undef;
		$self->{'FTPRAWMSG'}=undef;
		return undef;# unless defined($read);
	};
	return $self->responserest($read);
}

sub responserest ($$) {
	my ($self,$read)=@_;
	my $sock=$self->{'Sock'};
	my ($resp,$code,$cont,$msg);
	$resp=$read;
#UWAGA!
# wcale nieprawda to co nizej pisze. Jesli pierwsza linijka to \d\d\d-
#  to odbierac linijki az do napotkania \d\d\d\s
#  np:
#  226-EDI processing started
#   01 costam...
#   02 costam..
#  226 ...EDI processing complete


# Responsy maja format \d\d\d
#  lub wielolinijkowe: \d\d\d-
	print STDERR "SRV Response: $read" if $self->{Debug};
	$read=~/^(\d\d\d)\s(.*)/  && do {
		$code=$1;$msg=$2;chomp($msg);
	};
	$read=~/^(\d\d\d)-(.*)/  && do {
		$cont=1;$code=$1;$msg.=$2;
		print STDERR "wielolinijkowa odpowiedz z servera.." if $self->{Debug};
	};
	if ($read=~/^(\d\d\d)\s(.*)/m) {$cont=0;}; # wyjatek na wielolinijkowe na dziendobry
	if ($cont) {
		do {
			$read=<$sock>;
			$resp.=$read;
			$read=~/^(\d\d\d)-(.*)/  && do {$cont=1;$code=$1;$msg.=$2;};
			$read=~/^(\d\d\d)\s(.*)/  && do {$cont=0;$code=$1;$msg.=$2;};
			print " ----> $read\n" if $self->{Debug};
		} until ($cont==0);
	};
	$self->{'FTPCODE'}=$code;
	$self->{'FTPMSG'}=$msg;
	#$resp=~s/^\d\d\d\s/;
	$self->{'FTPRAWMSG'}=$resp;

	if ($code>399) {
#warn "Jaki¶ problem, chyba najlepiej sie wycofac\n";
#warn $resp;
#		print STDERR "ERR: $resp\n";
#warn "Server said we're bad.";
		$self->{'ErrMSG'}=$resp;
		return undef;
	};
	print STDERR "RECV: ",$resp if $self->{Debug};
	return $msg;
}

sub list {return nlst(@_);};
sub nlst {
	my ($self,$mask)=@_;
	my $sock=$self->{'Sock'};
	my $socket;
	my (@files)=();
	$socket=$self->datasocket();
	if (defined($socket)) {
		my $response;
		if (defined($mask)) {
			$response=$self->command("NLST $mask");
		} else {
			$response=$self->command("NLST");
		};
#print STDERR "ReSPONSE: -> : $response\n";
		#print "KOD : ",$self->{'FTPCODE'},"\n";
		# 1xx - cos jeszcze bedzie
		# 2xx - to juz koniec
		if ($response && ($self->{'FTPCODE'}<200) ) {

			if ($self->{"EncryptData"}==1) {
				{my $io=new IO::Handle;	tie(*$io, "Net::SSLeay::Handle", $socket);$socket = \*$io;};
				print STDERR "SSL for data connection enabled...\n" if $self->{Debug};
			};
			my $tmp;
			if ( $self->{'Compress'} ) {
				my $x = new Compress::Raw::Zlib::Inflate()
					or die "Cannot create a inflation stream\n" ;
				my $buf;my $read;

				my ($output, $status) ;
				while (sysread($socket,$buf,BUFSIZE)) 
				{
					$status = $x->inflate($buf, $output) ;
					$read+=length($output);
					#print $output ;
 					print STDERR "LST: $output\n" if $self->{Debug};
					$output=~s/\r\n$//;
					push @files,$output;

					last if $status != Z_OK ;
				};
				die "inflation failed\n"
					    unless $status == Z_STREAM_END ;

#				print STDERR "===> READ: $read\n";

			} else {
			#TODO: if {'Compress'}
				while ($tmp=<$socket>) {
	#print STDERR "G: $q";
	#chop($tmp);chop($tmp);#\r\n -> remove.
					$tmp=~s/\r\n$//;
					push @files,$tmp;
				};
			}
		};
		close $socket;
		if ($response && ($self->{'FTPCODE'}<200) ) {if ($response) {$response=$self->response();};}
		print STDERR "resp(end LIST) ",$response if $self->{Debug};
		return \@files if $response;
	};
	return 0;
};

sub putblat {
	my ($putorblat,$stororappe,$self,$remote,$local)=@_;
	my $socket;
	my $sock=$self->{'Sock'};
	$local=$remote unless defined($local);
	$self->command("TYPE I") unless ($self->{'DontDoType'});
	$socket=$self->datasocket();
	warn "SOCKET NOT CONNECTED! $!\n" unless defined($socket);
	if ($self->{"EncryptData"}!=0) {$self->command("PROT P"); };
	my $r=$self->command("$stororappe $remote");
	if (!$r) {
		print  STDERR "Problem trying to put file" if $self->{Debug};
		return $r;
	};

	if ($self->{"EncryptData"}==1) {
		{my $io=new IO::Handle;	tie(*$io, "Net::SSLeay::Handle", $socket);$socket = \*$io;};
		print STDERR "SSL for data connection enabled...\n" if $self->{Debug};
	};

	print STDERR "$stororappe connection opened.\n" if $self->{Debug};
	select($socket);
#print "selected.\n";
	if ($putorblat=~/put/) {
		# 


		CORE::open(L,"$local") or die "Can't open file $local, $!";
		binmode L;
		my $buf;

		if ($self->{'Compress'}) {
			#my $x = new Compress::Raw::Zlib::Deflate ( -Bufsize => 8192, -Level=> 1,-Strategy=>Z_DEFAULT_STRATEGY,-WindowBits=>15) 
			my $x = new Compress::Raw::Zlib::Deflate ( -Bufsize => $self->{"CompressionBufsize"}, -Level=> $self->{"CompressionLevel"},-Strategy=>$self->{"CompressionStrategy"},-WindowBits=>$self->{"CompressionWindowBits"}) 
				or die "Cannot create compression stream $!";
			#deflate $local => $socket,AutoClose=>1,BinModeIn=>1
		#		or die "Cannot compress to $socket $DeflateError $!";
				#
			my $read=0;my $circular=0;
			my ($output, $status) ;
			#while ($buf=<L>)
			while ( sysread(L,$buf,BUFSIZE))
			{
				$status = $x->deflate($buf, $output) ;
				$status == Z_OK
					or die "deflation failed $!\n" ;
				print $output ;
				#print STDERR "GOT ".length($output)." bytes from deflation\n";
				$read+=length($buf);
				#$circular+=length($buf);
				#if ($circular>8192) {
				#	$circular=0;
				#	print STDERR "trying part-flush\n";
				#	$status = $x->flush($output,Z_SYNC_FLUSH) ;
				#	$status == Z_OK
				#		or die "deflation failed $!\n" ;
				#	print $output ;
				#	print STDERR "GOT ".length($output)." bytes from no-flush-deflation\n";
				#};
 				if (defined ($self->{'PutUpdateCallback'})) {$self->{'PutUpdateCallback'}->( length($buf) ); };#TODO send sth..

			}
			print STDERR "out of buf LOOP\n" if $self->{Debug};
			$status = $x->flush($output) ;
			$status == Z_OK
				or die "deflation failed $!\n" ;
			#print $output ;
			syswrite($socket, $output) ;
			print STDERR "GOT ".length($output)." bytes from flush-deflation\n" if $self->{Debug};

		} 
		else {
			while ($buf=<L>) {
				print $buf;
				if (defined ($self->{'PutUpdateCallback'})) {$self->{'PutUpdateCallback'}->( length($buf) ); };#TODO send sth..
			};#Probably syswrite/sysread would be smarter..
		}
		close L;
	} else {
		if ($self->{'Compress'}) {
			my $x = new Compress::Raw::Zlib::Deflate ( -Bufsize => 8192) 
				or die "Cannot create compression stream $!";
			my $output;
			my $status = $x->deflate($local, $output) ;
			$status == Z_OK
				or die "deflation failed\n" ;
			#print $output ;
			syswrite($socket, $output) ;
			$status = $x->flush($output) ;
			$status == Z_OK
				or die "deflation failed\n" ;
			#print $output ;
			syswrite($socket, $output) ;
		} else {
			#print $local;
			syswrite($socket, $local) ;
		};
		if (defined ($self->{'PutUpdateCallback'})) {$self->{'PutUpdateCallback'}->( length($local) ); };#TODO send sth..
	}
#print "after write...\n";
	select(STDOUT);
	$socket->flush();
	close $socket;
	my $response=$self->response();
	print  STDERR "resp(after$stororappe) ",$response if $self->{Debug};
	if (defined $self->{'PutDoneCallBack'}) {$self->{'PutDoneCallBack'}->($response);};
	return $self->{'FTPRAWMSG'};
};
sub put {
	putblat('put','STOR',@_);
};
sub blat {
	putblat('blat','STOR',@_);
};
sub appe {
	putblat('put','APPE',@_);
};
sub blatappe {
	putblat('blat','APPE',@_);
};

sub get {
	getslurp('get',@_);
};
sub slurp {
	getslurp('slurp',@_);
};

sub getslurp {
	my ($getorslurp,$self,$remote,$local)=@_;
	my $socket;
	my $sock=$self->{'Sock'};
	$local=$remote unless defined($local);
	$self->command("TYPE I");
	$socket=$self->datasocket();
	#tmp
	#setsockopt($sock,&SOL_SOCKET,&SO_KEEPALIVE,undef,undef) || warn "setsockopt: $!";
	setsockopt($socket, SOL_SOCKET, SO_SNDTIMEO, pack('L!L!', 15, 0) ) or warn "setsockopt SNDTIMEO: ".$!;  
	setsockopt($socket, SOL_SOCKET, SO_RCVTIMEO, pack('L!L!', 15, 0) ) or warn "setsockopt RCVTIMEO: ".$!;
	setsockopt($socket, SOL_SOCKET, SO_KEEPALIVE, 1 ) or warn "setsockopt KEEPALIVE: ".$!;  
	setsockopt($socket, IPPROTO_IP, IP_TOS(), pack("I*",0x08 )) or warn "setsockopt TOS THROUGPHUT problem: $!";#THROUGHPUT
	#end tmp 2008-11-04

	if ($self->{"EncryptData"}!=0) {$self->command("PROT P"); };
	my $r=$self->command("RETR $remote");
	if (!$r) {
		print  STDERR "Problem trying to get file($remote)" if $self->{Debug};
		return $r;
	};

	if ($self->{"EncryptData"}==1) {
		{my $io=new IO::Handle;	tie(*$io, "Net::SSLeay::Handle", $socket);$socket = \*$io;};
		print  STDERR "SSL for data connection(RETR) enabled...\n" if $self->{Debug};
	};
	my $slurped="";
	if ($getorslurp=~/get/) {
		print STDERR "getorslurp: get\n" if $self->{Debug};
		CORE::open(L,">$local") or die("Can't open file for writing $local, $!");
		binmode L;
		my $tmp;my $cntr=0;


		if ($self->{'Compress'}) {
			#my $z = new IO::Uncompress::Inflate $socket, AutoClose=>1,Strict=>1
			#	or die "IO::Uncompress::Inflate failed: $InflateError\n";
			#inflate $socket => "ftp.".$local, AutoClose=>1 
			#	or die "Cannot decompress from $socket to $local $InflateError $!";

			        
			my $x = new Compress::Raw::Zlib::Inflate()
				or die "Cannot create a inflation stream\n" ;
			my $buf;my $read;

			my ($output, $status) ;
			while (sysread($socket,$buf,BUFSIZE)) 
			{
				$status = $x->inflate($buf, $output) ;
				$read+=length($output);
				#print $output ;
				print L $output;
				print STDERR length($output),":;".++$cntr."\n" if $self->{Debug};
				if (defined ($self->{'GetUpdateCallback'})) {$self->{'GetUpdateCallback'}->(length($output)); };#TODO send sth..
				last if $status != Z_OK ;
			};
			die "inflation failed\n"
				    unless $status == Z_STREAM_END ;

#			print STDERR "===> READ: $read\n";
		} else 
		{
# TODO replace while <$socket> with
# TODO while sysread($sock,$tmp,BUFSIZE);

			while (sysread($socket,$tmp,BUFSIZE)) {
				print L $tmp;
				print STDERR length($tmp),":;".++$cntr."\n" if $self->{Debug};
				if (defined ($self->{'GetUpdateCallback'})) {$self->{'GetUpdateCallback'}->(length($tmp)); };#TODO send sth..
			};
	#tmp-2008-10-22#		while ($tmp=<$socket>) {
	#tmp-2008-10-22#			print L $tmp;
	#tmp-2008-10-22#			print STDERR length($tmp),":;\n" if $self->{Debug};
	#tmp-2008-10-22#			if (defined ($self->{'GetUpdateCallback'})) {$self->{'GetUpdateCallback'}->();print STDERR "GUC defined, and has been called\n"; };#TODO send sth..
	#tmp-2008-10-22#		};
			close L;
		}
	} else {

		print STDERR "getorslurp: slurp($getorslurp)\n" if $self->{Debug};
		my $tmp;

		if ($self->{'Compress'}) {
			my $x = new Compress::Raw::Zlib::Inflate()
				or die "Cannot create a inflation stream\n" ;
			my $buf;my $read;

			my ($output, $status) ;
			while (sysread($socket,$buf,BUFSIZE)) 
			{
				$status = $x->inflate($buf, $output) ;
				$read+=length($output);
				#print $output ;
				$slurped.=$output;
				print STDERR length($output),":slurpZ;" if $self->{Debug};
				if (defined ($self->{'GetUpdateCallback'})) {$self->{'GetUpdateCallback'}->(length($output)); };#TODO send sth..
				last if $status != Z_OK ;
			};
			die "inflation failed\n"
				    unless $status == Z_STREAM_END ;


		} else {
			while ($tmp=<$socket>) {
				$slurped.=$tmp;print STDERR ":slurp." if $self->{Debug}; 
				if (defined ($self->{'GetUpdateCallback'})) {$self->{'GetUpdateCallback'}->( length($tmp) ); };#TODO send sth..
			};
		};
	};
	close $socket;
	my $response=$self->response();
	print STDERR "resp(afterRETR) ",$response if $self->{Debug};
	if (defined $self->{'GetDoneCallBack'}) {$self->{'GetDoneCallBack'}->($response);};
	return $slurped;
};

sub datasocket {
	my ($self)=@_;
	my ($tmp,$socket);
	if ($tmp=$self->command("PASV")) {
		if ($self->msgcode()==227 &&  $tmp=~/[^\d]*(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)/) {
			my $port=$5*256+$6;
			my $host="$1.$2.$3.$4";
			print STDERR "PASV port is $port ( $host )\n" if $self->{Debug};
			if (defined($self->{'ForcePASVIP'})) {$host=$self->{'ForcePASVIP'};print STDERR "Forcing PASV IP to $host\n" if $self->{Debug}};
			$socket = Net::SSLeay::Handle->make_socket($host, $port);
			setsockopt($socket, IPPROTO_IP, IP_TOS(), pack("I*",0x08 ));#THROUGHPUT
			if (defined($socket)) {
				print STDERR "Data link connected.. to $host at $port\n" if $self->{Debug};
			} else {
				warn "Data link NOT connected ($host,$port) $!";
				die "Data link NOT connected ($host,$port) $!";
			};
		} else {
			die "Problem parsing PASV response($tmp)";
		};
	} else {
		warn "undefined response to PASV cmd (err:$!) {H: ".$self->{'Host'}." P:".$self->{'Port'}."}\n";# unless defined($read);
		die "Problem sending PASV request, $tmp";
	};# end if self -> command PASV
	return $socket
};

sub trivialm {
	my ($self)=@_;
	return 1;
};

# extras...
#
sub registerGetUpdateCallback {
	my ($self,$callback_ref)=@_;

	$self->{'GetUpdateCallback'} = $callback_ref;
}
sub registerGetDoneCallback {
	my ($self,$callback_ref)=@_;

	$self->{'GetDoneCallback'} = $callback_ref;
}
sub registerPutUpdateCallback {
	my ($self,$callback_ref)=@_;

	$self->{'PutUpdateCallback'} = $callback_ref;
}
sub registerPutDoneCallback {
	my ($self,$callback_ref)=@_;

	$self->{'PutDoneCallback'} = $callback_ref;
}

sub setup_protection {
	my ($self)=@_;
	if ($self->{'Encrypt'}) {
		$self->command("PBSZ 0");# TODO
		if ($self->{"EncryptData"}!=0) {$self->command("PROT P"); };
	} else {return 1;};
};


sub check_raw_socket {
	my ($self)=@_;
	use Socket;
	my $s=$self->{'RAWSock'};
	my $hersockaddr    = getpeername($s);
	my ($port, $iaddr) = sockaddr_in($hersockaddr);
	return $s->eof."$hersockaddr $port $iaddr";
};



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Lite::FTP - Perl FTP client with support for TLS

=head1 SYNOPSIS

    use Net::Lite::FTP;
    my $tlsftp=Net::Lite::FTP->new();
    $tlsftp->open("ftp.tls.pl","21");
    $tlsftp->user("user");
    $tlsftp->pass("password");
    $tlsftp->cwd("pub");
    my $files=$tlsftp->nlst("*.exe");
    foreach $f (@files) {
        $tlsftp->get($f);
    };


=head1 DESCRIPTION

Very simple FTP client with support for TLS

=head1 SEE ALSO

L<Net::FTP>
L<Tie::FTP>

ftp(1), ftpd(8), RFC 959
http://war.jgaa.com/ftp/rfc/rfc959.txt

http://war.jgaa.com/ftp/draft/draft-murray-auth-ftp-ssl-03.txt

http://www.ietf.org/internet-drafts/draft-murray-auth-ftp-ssl-10.txt

ftp://ftp.ietf.org/internet-drafts/draft-fordh-ftp-ssl-firewall-01.txt


=head1 AUTHOR

Dariush Pietrzak,'Eyck' E<lt>cpan@ghost.anime.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Dariush Pietrzak

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
   at your option, any later version of Perl 5 you may have available.


=cut

