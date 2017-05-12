package Net::WWD::ParserEngine;

#############################################
# WWD File parser for integration with Apache
# (C) Copyright 2001-2005 John Baleshiski
# All rights reserved.
#############################################

use warnings;
use CGI qw(:standard escapeHTML);
use HTTP::Request;
use LWP::UserAgent;
use HTTP::Headers;
use CGI::Carp "fatalsToBrowser";
use Apache::RequestRec ();
use Apache::RequestIO ();
use Data::Dumper;
use Apache::Const -compile => qw(OK);
use Time::Local;
use Net::WWD::Functions;

sub processWWDFile {
	my($fname, $sitename) = @_;
	open(FH,$fname);
	flock(FH,LOCK_EX);
	@lines = <FH>;
	close(FH);
	return processWWD($sitename, @lines);
}

sub processWWD {
	my $sitename = shift;
	my @lines = @_;

	my $text = "";
	my $wwdposition = 0;
	my $i = 0;
	while($i < @lines) {
		while($lines[$i] =~ /<wwd /i) {
			$preline = $`;
			if($' !~ />/i) { die "Error in WWD file - malformed wwd tag"; }
			$wwdlink = $`;
			$postline = $';
			if($wwdlink =~ /\/$/) { $wwdlink = $`; }
			$wwdlink =~ s/\s$//g;
			$wwdlink = ConvertLink($wwdlink, $sitename);
			$lines[$i] = $preline.$wwdlink.$postline;
		}
		while($lines[$i] =~ /<wwget /i) {
			$preline = $`;
			if($' !~ />/i) { die "Error in WWD file - wwget does not have an ending"; }
			$wwdlink = $`;
			$postline = $';
			if($wwdlink =~ /\/$/) { $wwdlink = $`; }
			$wwdlink =~ s/\s$//g;
			$wwdlink = ConvertGet($wwdlink, $sitename);
			$lines[$i] = $preline.$wwdlink.$postline;
		}
		while($lines[$i] =~ /<wwparam /i) {
			$preline = $`;
			if($' !~ />/) { die "Error in WWD file - wwparam does not have an ending"; }
			$paramn = $`;
			$postline = $';
			if($paramn =~ /\/$/) { $paramn = $`; }
			$paramn =~ s/\s$//g;
			$lines[$i] = $preline.$params{$paramn}.$postline;
		}
		$text .= $lines[$i];
		$i++;
	}
	if(@lines == 0) {
		return "WWD Error - file could not be found.  Please check your links!";
	} else {
		while($text =~ /<dperl>/i) {
			$preline = $`;
			if($' !~ /<\/dperl>/) { die "Error in WWD file - dperl does not have an ending"; }
			$paramn = $`;
			$postline = $';
			$paramn = eval(Net::WWD::Functions::stripPerl($paramn));
			$text = $preline.$paramn.$postline;
		}
		return $text;
	}
	return "";
}

sub ConvertLink {
	my($wwdlink, $sitename) = @_;

	my $user = "";
	my $pw = "";
	if($wwdlink =~ /user=/i) {
		my $pre = $`;
		my $post = $';
		if($post =~ / /) {
			$user = $`;
			$wwdlink = $pre . $';
		}
	}

	if($wwdlink =~ /password=/i) {
		my $pre = $`;
		my $post = $';
		if($post =~ / /) {
			$pw = $`;
			$wwdlink = $pre . $';
		}
	}
	if($wwdlink !~ /\//) { die "WWD LINK[$wwdlink] Bad format!"; }
	my $site = $`;
	my $link = $';
	if(lc($site) eq "localhost") { $site = Net::WWD::Functions::localhost(); }
	if(lc($site) eq "localdomain") { $site = Net::WWD::Functions::localdomain(); }
	my $s = GetWWDLink($site,$link,$sitename,$user,$pw);

	my $errmsg = "<FONT STYLE=\"background-color:red; color:white;\"> <B>WWD ERROR: [${site}/${link}] LINK NOT FOUND</B> </FONT>";
	if($s eq $errmsg) { $s = GetWWDLink("defaultobjects",$link,$sitename,$user,$pw); }
	return $s;
}

sub ConvertGet {
	my($wwgetlink, $sitename) = @_;

	if($wwgetlink !~ / /) { die "WWGET LINK[$wwgetlink] Bad format!"; }

	if($wwgetlink =~ /^http:\/\//) { $wwgetlink = $'; }
	if($wwgetlink =~ /\//) {
		my $site = $`;
		my $link = $';
		if(lc($site) eq "localhost") { $site = Net::WWD::Functions::localhost(); }
		if(lc($site) eq "localdomain") { $site = Net::WWD::Functions::localdomain(); }
		$wwgetlink = $site.$link;
	}

	return Net::WWD::Functions::webget("http://" . $wwgetlink);
}

sub getCookie {
	my $c = shift;
	my $cookies = $ENV{'HTTP_COOKIE'};
	if($cookies =~ /${c}=/) { $cookies = $'; }
	if($cookies =~ /;/) { $cookies = $`; }
	return $cookies;
}

sub currentUser {
	my $user = $params{"un"};
	my $pass = $params{"pw"};
	my $host = Net::WWD::Functions::localdomain();
	my $cookies = $ENV{'HTTP_COOKIE'};
	if($user eq "") {
		if($cookies =~ /un=/) { $user = $'; }
		if($user =~ /;/) { $user = $`; }
	}
	if($pass eq "") {
		if($cookies =~ /pw=/) { $pass = $'; }
		if($pass =~ /;/) { $pass = $`; }
	}

	open(FH,"/usr/share/wwd/users");
	flock(FH,LOCK_EX);
	while(<FH>) {
		if($_ =~ /$host:$user:/) {
			$strPW = $';
			if($strPW =~ /:/) { $strPW = $`; }
			if($strPW eq $pass) {
				return $user;
			}
		}
	}
	close(FH);
	return "";
}


sub GetWWDLink {
	my($sitename, $linkname, $mysitename, $user, $pw) = @_;

	my $username = currentUser();
	my $param = "";
	$linkname =~ s/currentuser\//$username\//g;
	$linkname =~ s/\/currentuser/\/$username/g;
	if($linkname =~ /\s/) { $linkname = $`; $param = $'; }
	my $entryspec = $linkname."=";
	$sitename = lc($sitename);
	my $fname = "/usr/share/wwd/data/${sitename}/${linkname}";
	if(!-e $fname) {
		if(-e "/usr/share/wwd/cache/${sitename}/${linkname}") {
			open(FH,"/usr/share/wwd/cache/${sitename}/${linkname}");
			flock(FH,LOCK_EX);
			my $data = <FH>;
			close(FH);
			my($rp,$timestamp,$ttl,$value) = split(/:/, $data);
			$value =~ s/\&colon;/\:/g;
			my $passwordOK = 0;
			if($rp eq "") { $passwordOK = 1; }
			elsif($rp eq $pw) { $passwordOK = 1; }
			if(($ttl > time)&&($passwordOK)) { return processPerl($value, $param); }
			if(!$passwordOK) { return "Invalid password!"; }
		}
		my $s = "http://${sitename}/wwd/wwd.cgi?host=" . $ENV{'REMOTE_ADDR'} . "&t=${linkname}&p=${pw}";
		my $result = Net::WWD::Functions::webget($s);
		chomp($result);
		my($timestamp,$ttl,$data) = "";
		if($result =~ /:/) { $timestamp = $`; $result = $'; }
		if($result =~ /:/) { $ttl = $`; $data = $'; }

		$data =~ s/\&colon;/\:/g;
		if($ttl eq "") { $ttl = time + "86400"; }
		if($ttl ne "-1") {
			mkdir("/usr/share/wwd/cache/${sitename}");
			my $x = $linkname;
			my $dir = "/usr/share/wwd/cache/${sitename}";
			while($x =~ /\//) {
				$dir .= "/" . $`;
				$x = $';
				mkdir($dir);
			}
			open(FH,">/usr/share/wwd/cache/${sitename}/${linkname}");
			flock(FH,LOCK_EX);
			my $newttl = eval($ttl + time);
			if($ttl eq "") { $newttl = "999999999999999999999999999999999999"; }
			$data =~ s/\:/\&colon;/g;
			print FH "${pw}:${timestamp}:${newttl}:${data}";
			close(FH);
		}
		return processPerl($data, $param);
	} else {
		my $noauth = "-1:-1:<FONT STYLE=\"background-color:red; color:white;\"><B>WWD ERROR: You are not authorized to read this link</B></FONT>";
		my $s = "";
		open(FH,$fname);
		flock(FH,LOCK_EX);
		my @tag = <FH>;
		close(FH);
		$s = $tag[0];
		chomp($s);
		if(!Net::WWD::Functions::canAccess($tag[6], $ENV{'REMOTE_ADDR'}, $fname)) { return $noauth; }
		if(Net::WWD::Functions::invalidPassword($user, $pw, $tag[5], $tag[3], $fname)) { return $noauth . "(xinvalid password)"; }
		# verify tmp read password # if no read pw but tmp pw assert pw == tmp pw # verify read password	
		return processPerl($s, $param);
	}
	return "-1:-1:<FONT STYLE=\"background-color:red; color:white;\"> <B>WWD ERROR: [${sitename}/${linkname}] LINK NOT FOUND</B> </FONT>";
}

sub processPerl {
	my $link = shift;
	my $param = shift;
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
	return $link;
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
	my $noauth = "<FONT STYLE=\"background-color:red; color:white;\"><B>WWD ERROR: You are not authorized to read this link</B>";
	if(-e $fname) {
		my $s = "";
		open(FH,$fname);
		flock(FH,LOCK_EX);
		my @tag = <FH>;
		close(FH);
		for(my $i=0; $i<@tag; $i++) { chomp($tag[$i]); }
		$s = $tag[0];
		my $firstdata = "${tag[7]}:${tag[4]}:";
		if($raw eq "1") { $firstdata = ""; }
		if(!Net::WWD::Functions::canAccess($tag[6], $ENV{'REMOTE_ADDR'}, $fname)) { return $noauth . "</FONT>"; }
		elsif(Net::WWD::Functions::invalidPassword($o, $rp, $tag[5], $tag[3], $fname)) { return $noauth . "(iinvalid password)</FONT>"; }
		else { return $firstdata . processPerl($s,$param); }
	} else { return "<FONT STYLE=\"background-color:red; color:white;\"> <B>WWD ERROR: [${host}/${t}] LINK NOT FOUND</B> </FONT>"; }
}

1;
