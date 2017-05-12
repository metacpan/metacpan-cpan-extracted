package Net::WWD::Functions;

#######################################
# WorldWide Database Client Package   #
# Copyright 2000-2005 John Baleshiski #
# All rights reserved.                #
#######################################
# Version 0.50 - Initial release

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(stripPerl) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(stripPerl);
our $VERSION = '1.00';

use XML::LibXML;
use HTTP::Headers;
use HTTP::Request;
use LWP::UserAgent;

my $XMLparser = XML::LibXML->new();
my $header = HTTP::Headers->new('content-type' => 'text/html');
my $ua = LWP::UserAgent->new;

sub localhost { return $ENV{'SERVER_NAME'}; }
sub localdomain { return splitdomain($ENV{'SERVER_NAME'}); }

sub splitdomain {
	my $domain = shift;
	my $suffix = "";
	$domain = reverse $domain;
	if($domain =~ /\./) {
		$suffix = $` . ".";
		$domain = $';
	} else { return ""; }
	if($domain =~ /^..\./) {
		$suffix .= $&;
		$domain = $';
	}
	if($domain =~ /\./) { $domain = $`; }
	return (reverse $domain) . (reverse $suffix);
}

sub stripPerl {
	my $code = shift;

        $code =~ s/localhost\(/Net\:\:WWD\:\:Functions\:\:localhost\(/g;
        $code =~ s/localdomain\(/Net\:\:WWD\:\:Functions\:\:localdomain\(/g;
        $code =~ s/getTag\(/Net\:\:WWD\:\:Functions\:\:getTag\(/g;
        $code =~ s/webget\(/Net\:\:WWD\:\:Functions\:\:webget\(/g;
        $code =~ s/currentURL\(/Net\:\:WWD\:\:Functions\:\:currentURL\(/g;
        $code =~ s/getData\(/Net\:\:WWD\:\:Functions\:\:getData\(/g;
        $code =~ s/storeData\(/Net\:\:WWD\:\:Functions\:\:storeData\(/g;
        $code =~ s/parseXML\(/Net\:\:WWD\:\:Functions\:\:parseXML\(/g;
        $code =~ s/\$param/DPERLPARAM/g;
        $code =~ s/\$ENV/DPERLENV/g;
        $code =~ s/\$\`/DPERLMPRE/g;
        $code =~ s/\$\'/DPERLMPOST/g;
	$code =~ s/\s+\(/\(/g;
	$code =~ s/\`//g;
	$code =~ s/\@/\@WWD/g;
	$code =~ s/\$/\$WWD/g;
#	$code =~ s/\&//g;
	$code =~ s/\%//g;
	$code =~ s/accept\(//g;
	$code =~ s/bind\(//g;
	$code =~ s/binmode\(//g;
	$code =~ s/chdir\(//g;
	$code =~ s/chmod\(//g;
	$code =~ s/chown\(//g;
	$code =~ s/chroot\(//g;
	$code =~ s/close\(//g;
	$code =~ s/closedir\(//g;
	$code =~ s/connect\(//g;
	$code =~ s/dbmclose\(//g;
	$code =~ s/dbmopen\(//g;
	$code =~ s/die\(//g;
	$code =~ s/dump\(//g;
	$code =~ s/endgrent\(//g;
	$code =~ s/endhostent\(//g;
	$code =~ s/endnetent\(//g;
	$code =~ s/endprotoent\(//g;
	$code =~ s/endpwent\(//g;
	$code =~ s/endservent\(//g;
	$code =~ s/eof\(//g;
	$code =~ s/eval\(//g;
	$code =~ s/exit\(//g;
	$code =~ s/fcntl\(//g;
	$code =~ s/fileno\(//g;
	$code =~ s/flock\(//g;
	$code =~ s/fork\(//g;
	$code =~ s/format\(//g;
	$code =~ s/getc\(//g;
	$code =~ s/getgrent\(//g;
	$code =~ s/getgrgid\(//g;
	$code =~ s/getgrnam\(//g;
	$code =~ s/gethostbyaddr\(//g;
	$code =~ s/gethostbyname\(//g;
	$code =~ s/gethostent\(//g;
	$code =~ s/getlogin\(//g;
	$code =~ s/getnetbyaddr\(//g;
	$code =~ s/getnetent\(//g;
	$code =~ s/getnetbyname\(//g;
	$code =~ s/getprotobyname\(//g;
	$code =~ s/getprotobynumber\(//g;
	$code =~ s/getprotoent\(//g;
	$code =~ s/getpwent\(//g;
	$code =~ s/getpwnam\(//g;
	$code =~ s/getpwuid\(//g;
	$code =~ s/getservbyname\(//g;
	$code =~ s/getservbyport\(//g;
	$code =~ s/getservent\(//g;
	$code =~ s/glob\(//g;
	$code =~ s/import\(//g;
	$code =~ s/ioctl\(//g;
	$code =~ s/kill\(//g;
	$code =~ s/link\(//g;
	$code =~ s/listen\(//g;
	$code =~ s/lstat\(//g;
	$code =~ s/mkdir\(//g;
	$code =~ s/open\(//g;
	$code =~ s/opendir\(//g;
	$code =~ s/printf\(//g;
	$code =~ s/read\(//g;
	$code =~ s/readdir\(//g;
	$code =~ s/readlink\(//g;
	$code =~ s/recv\(//g;
	$code =~ s/rename\(//g;
	$code =~ s/require\(//g;
	$code =~ s/reset\(//g;
	$code =~ s/rewinddir\(//g;
	$code =~ s/rmdir\(//g;
	$code =~ s/seek\(//g;
	$code =~ s/seekdir\(//g;
	$code =~ s/select\(//g;
	$code =~ s/send\(//g;
	$code =~ s/setgrent\(//g;
	$code =~ s/sethostent\(//g;
	$code =~ s/setnetent\(//g;
	$code =~ s/setprotoent\(//g;
	$code =~ s/setpwent\(//g;
	$code =~ s/setservent\(//g;
	$code =~ s/shutdown\(//g;
	$code =~ s/socket\(//g;
	$code =~ s/socketpair\(//g;
	$code =~ s/stat\(//g;
	$code =~ s/symlink\(//g;
	$code =~ s/syscall\(//g;
	$code =~ s/sysopen\(//g;
	$code =~ s/sysread\(//g;
	$code =~ s/sysseek\(//g;
	$code =~ s/system\(//g;
	$code =~ s/syswrite\(//g;
	$code =~ s/tell\(//g;
	$code =~ s/telldir\(//g;
	$code =~ s/truncate\(//g;
	$code =~ s/umask\(//g;
	$code =~ s/unlink\(//g;
	$code =~ s/use\(//g;
	$code =~ s/utime\(//g;
	$code =~ s/warn\(//g;
	$code =~ s/write\(//g;
	$code =~ s/\$wwd//g;
        $code =~ s/DPERLPARAM/\$param/g;
        $code =~ s/DPERLENV/\$ENV/g;
        $code =~ s/DPERLMPRE/\$\`/g;
        $code =~ s/DPERLMPOST/\$\'/g;
        $code =~ s/DPERLDOLLAR/\$/g;
	return $code;
}

sub currentURL {
	return "http://" . $ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'};
}

sub getData {
	my($name) = @_;
	$name =~ s/[^A-Za-z0-9]//g;

	open(FH,"/usr/share/wwd/data-store/${name}");
	flock(FH,LOCK_EX);
	my $strS = <FH>;
	close(FH);

	my @fInfo = stat "/usr/share/wwd/data-store/${name}";
	return ($strS,$fInfo[9]);
}

sub storeData {
	my($name,$value) = @_;
	$name =~ s/[^A-Za-z0-9]//g;

	open(FH,">/usr/share/wwd/data-store/${name}");
	flock(FH,LOCK_EX);
	print FH $value;
	close(FH);
}

sub parseXML {
	my($xml,$node) = @_;
	my $graph = $XMLparser->parse_string($xml);
	return $graph->findvalue($node);
}

sub webget {
	my($url) = @_;
	my $req = HTTP::Request->new(GET,$url,$header,"");
	my $resp = $ua->request($req);
	my $lines = $resp->as_string();
	if($lines =~ /\n\n/) { $lines = $'; }
	return $lines;
}

sub getTag {
	my ($host, $tag, $o, $rp) = @_;
	if(!defined $o) { $o = ""; }
	if(!defined $rp) { $rp = ""; }
	my $s = viewTag($host, $tag, $o, $rp);

	if($s =~ /\:/) { $s = $'; }
	if($s =~ /\:/) { $s = $'; }
	return $s;
}

sub invalidPassword {
	my ($user, $pw, $readpw, $tmppw, $fname) = @_;
	my $ttl = "";
	chomp($user);
	chomp($pw);
	chomp($readpw);
	chomp($tmppw);
	($ttl,$tmppw) = split(/;/, $tmppw);
	if(($ttl < time)&&($ttl ne "")) {
		open(FH,"+<${fname}");
		flock(FH,LOCK_EX);
		my @lines = <FH>;
		seek(FH, 0, 0);
		truncate(FH, 0);
		$lines[3] = "\n";
		for(my $i=0; $i<@lines; $i++) { print FH $lines[$i]; }
		close(FH);
		$tmppw = "";
	}
	if($pw eq "") {
		if(($tmppw ne "")||($readpw ne "")) { return 1; }
		return 0;
	}
	if(($pw eq $tmppw)||($pw eq $readpw)) { return 0; }
	return 1;
}

sub canAccess {
	my($accesslist,$host,$fname) = @_;
	chomp($accesslist);
	if($accesslist eq "") { return 1; }
	my @allowed = split(/,/, $accesslist);
	for(my $i=0; $i<@allowed; $i++) {
		if($allowed[$i] =~ /;/) {
			my $s = $`;
			my $times = $';
			if(($s eq $host)||($s eq currentUser())) {
				setAccess($s, $times, $fname);
				return 1;
			}
		} else { if(($allowed[$i] eq $host)||($allowed[$i] eq currentUser())) { return 1; } }
	}
	return 0;
}

sub setAccess {
	my($host,$times, $fname) = @_;
	open(FH,"+<${fname}");
	flock(FH,LOCK_EX);
	my @lines = <FH>;
	seek(FH, 0, 0);
	truncate(FH, 0);
	chomp($lines[6]);
	my @list = split(/,/, $lines[6]);
	$lines[6] = "";
	for(my $i=0; $i<@list; $i++) {
		if($list[$i] =~ /$host;$times/) {
			$times--;
			if($times == 0) { $list[$i] = ""; }
			else { $list[$i] = "${host};${times}"; }
		}
		if($list[$i] ne "") { $lines[6] .= $list[$i] . ","; }
	}
	$lines[6] =~ s/,$//;
	$lines[6] .= "\n";
	for(my $i=0; $i<@lines; $i++) { print FH $lines[$i]; }
	close(FH);
}

1;
