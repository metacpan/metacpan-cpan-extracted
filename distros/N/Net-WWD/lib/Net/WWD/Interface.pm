package Net::WWD::Interface;

use warnings;
use HTTP::Request;
use LWP::UserAgent;
use HTTP::Headers;
use Apache::RequestRec ();
use Apache::RequestIO ();
use Apache::Const -compile => qw(OK);
use Data::Dumper;
use Time::Local;
use Net::WWD::ParserEngine;
use Net::WWD::Functions;

my %params;

sub handler {
	my $r = shift;
	$r->content_type('text/plain');
	my $req = $ENV{'REQUEST_URI'};
	if($req =~ /\?/) { $req = $'; } else { $req = ""; }
	my @p = split(/&/, $req);
	$params{'t'} = "";
	$params{'o'} = "";
	$params{'p'} = "";
	$params{'v'} = "";
	$params{'a'} = "";
	$params{'tp'} = "";
	$params{'rp'} = "";
	$params{'mp'} = "";
	$params{'ttl'} = "";
	$params{'ac'} = "";
	for(my $i=0; $i<@p; $i++) {
		my ($s, $t) = split(/=/, $p[$i]);
		$params{$s} = $t;
	}
	if($r->method eq 'POST') {
		my %tmp = $r->content;
		my @s;
		foreach my $v (%tmp) { $s[@s] = $v; }
		for(my $i=0; $i<@s; $i+=2) {
			$params{$s[$i]} = $s[$i+1];
		}
	}

	my $ac = $params{'ac'};
	if($params{'t'} =~ /^localhost\//) { $params{'t'} = Net::WWD::Functions::localhost() ."/". $'; }
	if($params{'t'} =~ /^localdomain\//) { $params{'t'} = Net::WWD::Functions::localdomain() ."/". $'; }
	if($ac eq "save")	{ print saveTag($ENV{'SERVER_NAME'}); }
	elsif($ac eq "add")	{ print addTag($ENV{'SERVER_NAME'}); }
	elsif($ac eq "del")	{ print delTag($ENV{'SERVER_NAME'}); }
	else {
		my $s = viewTag($ENV{'SERVER_NAME'}, $params{'t'}, $params{'o'}, $params{'rp'}, $params{'raw'});
		if($s =~ /^0:-1:INVALID PERMISSION/) { $s = viewTag("defaultobjects",$params{'t'},$params{'o'},$params{'rp'},$params{'raw'}); }
		print $s;
	}

	return Apache::OK;
}

sub addTag {
	my $host = shift;
	my $o = currentUser();
	if($o eq "") { return "YOU NEED TO BE LOGGED IN TO CREATE A TAG"; }
	my ($t, $p, $v, $mp, $tp, $ttl, $rp, $a) = "";
	$t = $params{'t'};
	$t =~ s/[^A-Za-z0-9\-\_]//g;
	$p = $params{'p'};
	$v = $params{'v'};
	$mp = $params{'mp'};
	$tp = $params{'tp'};
	$ttl = $params{'ttl'};
	$rp = $params{'rp'};
	$a = $params{'a'};

	if(-e "/usr/share/wwd/data/${host}/${o}/${t}") { return "TAG ALREADY EXISTS"; }
	mkdir("/usr/share/wwd/data/${host}/${o}");
	open(FH,">/usr/share/wwd/data/${host}/${o}/${t}");
	flock(FH,LOCK_EX);
	print FH "${v}\n${o}\n${mp}\n${tp}\n${ttl}\n${rp}\n${a}\n" . time . "\n";
	close(FH);
	return "TAG CREATED for ${o}";
}

sub currentUser {
	my $username	= $params{'user'};
	my $pw		= $params{'pw'};
        $username =~ s/[^A-Za-z0-9]//g;
	$pw =~ s/\?$//;
	$domain = Net::WWD::Functions::localdomain();

	open(FH,"/usr/share/wwd/users");
	flock(FH,LOCK_EX);
	while(<FH>) {
		if($_ =~ /$domain:$username:/) {
			$strPW = $';
			if($strPW =~ /:/) { $strPW = $`; }
			if($pw eq $strPW) {
				close(FH);
				return $username;
			}
		}
	}
	close(FH);
	return "";
}

sub delTag {
	my $host = shift;
	$host = lc($host);
	my ($t, $o, $p, $v, $mp, $tp, $ttl, $rp, $a) = "";
	$t = $params{'t'};
	$o = currentUser();
	if($o eq "") { return "YOU NEED TO BE LOGGED IN TO CREATE A TAG"; }
	$p = $params{'p'};
	$v = $params{'v'};
	$mp = $params{'mp'};
	$tp = $params{'tp'};
	$ttl = $params{'ttl'};
	$rp = $params{'rp'};
	$a = $params{'a'};

	open(FH,"/usr/share/wwd/data/${host}/${t}");
	flock(FH,LOCK_EX);
	my @tag = <FH>;
	close(FH);
	my $owner = $tag[1];
	my $pw = $tag[2];
	chomp($owner);
	chomp($pw);
	if(($o ne $owner)||($p ne $pw)||($owner eq "")) { return "INVALID PERMISSION"; }
	unlink("/usr/share/wwd/data/${host}/${t}");
	return "TAG DELETED";
}

sub saveTag {
	my $host = shift;
	$host = lc($host);
	my ($t, $o, $p, $v, $mp, $tp, $ttl, $rp, $a) = "";
	$t = $params{'t'};
	$o = currentUser();
	if($o eq "") { return "YOU NEED TO BE LOGGED IN TO CREATE A TAG"; }
	$p = $params{'p'};
	$v = $params{'v'};
	$mp = $params{'mp'};
	$tp = $params{'tp'};
	$ttl = $params{'ttl'};
	$rp = $params{'rp'};
	$a = $params{'a'};

	my $tagname = "/usr/share/wwd/data/${host}/${o}/${t}";
	if(! -e $tagname) { return addTag($host); }
	open(FH,$tagname);
	flock(FH,LOCK_EX);
	my @tag = <FH>;
	close(FH);
	my $owner = $tag[1];
	my $pw = $tag[2];
	chomp($owner);
	chomp($pw);
	if(($o ne $owner)||($p ne $pw)||($owner eq "")) { return "INVALID PERMISSION"; }

	if($v ne "")	{ $tag[0] = $v . "\n"; }
	if($mp ne "")	{ $tag[2] = $mp . "\n"; }
	if($tp ne "")	{ $tag[3] = $tp . "\n"; }
	if($rp ne "")	{ $tag[5] = $rp . "\n"; }
	if($ttl ne "")	{ $tag[4] = $ttl . "\n"; }
	if($a ne "") {
		chomp($tag[6]);
		if($a =~ /^\-/)		{ $tag[6] = removeIP($tag[6], $'); }
		elsif($a =~ /^\+/)	{ $a = $'; if($tag[6] ne "") { $tag[6] .= ","; } $tag[6] .= $a . "\n"; }
		else				{ $tag[6] = $a . "\n"; }
	}
	$tag[7] = time . "\n";
	open(FH,">${tagname}");
	flock(FH,LOCK_EX);
	for(my $i=0; $i<@tag; $i++) {
		if($tag[$i] =~ /\$NULL\$\n/) { $tag[$i] = "\n"; }
		print FH $tag[$i];
	}
	close(FH);
	return "TAG MODIFIED";
}

sub removeIP {
	my($allowed, $ip) = @_;

	my @a = split(/,/, $allowed);
	$allowed = "";
	for(my $i=0; $i<@a; $i++) {
		my $reads = "";
		if($a[$i] =~ /;/) {
			$a[$i] = $`;
			$reads = $';
		}
		if($a[$i] ne $ip) {
			if($reads ne "") { $a[$i] .= ";${reads}"; }
			$allowed .= ",${a[$i]}";
		}
	}
	$allowed =~ s/^,//;
	return $allowed . "\n";
}

sub viewTag {
	my($host, $t, $o, $rp, $raw) = @_;
	my $username = currentUser();
	$t =~ s/currentuser\//$username\//g;
	$t =~ s/\/currentuser/\/$username/g;
	my $param = "";
	$t =~ s/\%20/ /g;
	if($t =~ / /) { $t = $`; $param = $'; }
	
	my $fname = "/usr/share/wwd/data/" . lc($host) . "/${t}";
	my $noauth = "0:-1:INVALID PERMISSION";
	if(-e $fname) {
		my $s = "";
		open(FH,$fname);
		flock(FH,LOCK_EX);
		my @tag = <FH>;
		close(FH);
		for(my $i=0; $i<@tag; $i++) { chomp($tag[$i]); }
		if($tag[6] =~ /localonly/i) { return "0:-1:[${host}/${t}] LINK IS LOCAL ONLY"; }
		$s = $tag[0];
		my $firstdata = "";
		if($tag[7] eq "") {
			my @frec = stat $fname;
			$tag[7] = $frec[9];
		}
		if($tag[4] eq "") { $tag[4] = "604800"; } # default TTL = 1 week
		$firstdata = "${tag[7]}:${tag[4]}:";
		if($raw eq "1") { $firstdata = ""; }

		if(!Net::WWD::Functions::canAccess($tag[6], $ENV{'REMOTE_ADDR'}, $fname)) {
			return $noauth;
		} elsif(Net::WWD::Functions::invalidPassword($o, $rp, $tag[5], $tag[3], $fname)) {
			return $noauth . " (bad password)";
		} elsif($raw eq "2") {
			return $firstdata.$s;
		} else {
			return $firstdata . processPerl($s,$param);
		}
	} else { return "0:-1:UNKNOWN OBJECT"; }
}

sub processPerl {
	my $link = shift;
	my $param = shift;
	my $sitename = Net::WWD::Functions::localdomain();
	return Net::WWD::ParserEngine::processWWD($sitename, ($link));

	if($link =~ /wwd:\/\//) {
		$url = $';
		$link = "";
		if($url =~ /\//) {
			$link = Net::WWD::Functions::webget("http://${`}/wwd/wwd.cgi?t=${'}");
			$link =~ s/\&colon;/\:/g;
			my($s1,$s2,$data) = split(/:/, $link);
			$link = $data;
		}
	}
	while($link =~ /<dperl>/i) {
		$link = $`;
		$code = $';
		if($code =~ /<\/dperl>/i) { 
			$code = Net::WWD::Functions::stripPerl($`);
			$link =  $link . eval ($code) . $';
		} else { $link = "INVALID SCRIPT IN LINK"; }
	}
	$link =~ s/\n$//g;
	return $link;
}

1;
