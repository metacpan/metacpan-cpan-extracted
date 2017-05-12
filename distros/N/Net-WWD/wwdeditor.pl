#!/usr/bin/perl

# World Wide Database Editor  Web Application
# Developed by Kaizen Technologies

# CHANGE HISTORY
# V0.01	29-SEP-03	John Baleshiski			Initial Version

$| = 1;

use CGI::Carp "fatalsToBrowser";
use CGI qw(:standard escapeHTML);
use Net::WWD::Client;
use Net::WWD::Functions;


$query = new CGI;
$wwd = new Net::WWD::Client;
$localdomain = Net::WWD::Functions::localdomain();
$footer = $wwd->get($localdomain,"wwd/footer");

$username = checkForLogin();
print "Content-Type: text/html\n\n" . $wwd->get($localdomain,"wwd/header");
if($username eq "") { showLoginScreen(); }

$basedir = "/usr/share/wwd/data/${localdomain}/${username}";
my $msg = "You are logged in as ${username}.  <a href=\"logout.cgi\">[LOGOUT]</a><br /><br />You are now editing all of your WWD Objects.<br /><br />";
my $a = $query->param('a');
if($a eq "") { $msg .= listWWD(); }
elsif($a eq "editent")		{ $msg .= editEntry(); $msg .= listWWD(); }
elsif($a eq "createent")	{ $msg .= createEntry(); $msg .= listWWD(); }
elsif($a eq "createdir")	{ $msg .= createDir(); }
elsif($a eq "deldir")		{ $msg .= deleteDir(); $msg .= listWWD("/"); }
elsif($a eq "delentry")		{ $msg .= deleteEntry(); $msg .= listWWD(); }
else				{ $msg .= "Unknown function!"; }
print $msg.$footer;

sub showLoginScreen {
	print "Please login to edit your objects<br /><br />";
	print '<form action="wwdeditor.pl" method="get">';
	print 'Username: <input type="text" name="un" id="un"><br />';
	print 'Password: <input type="password" name="pw"><br />';
	print '<input type="submit" value="Login">';
	print '</form>';
	print "\n<script language=\"javascript\">\ndocument.getElementById(\"un\").focus();\n</script>\n";
	print $footer;
	exit;
}

sub checkForLogin {
	my $user = $query->param("un");
	my $pass = $query->param("pw");
	if($user eq "") { $user = $query->cookie("Cun"); }
	if($pass eq "") { $pass = $query->cookie("Cpw"); }
	if($user eq "") { return ""; }
	my ($user, $domain) = split(/\@/, $user);
	if($domain ne "") { $localdomain = $domain; }
	open(FH,"/usr/share/wwd/users");
	flock(FH,LOCK_EX);
	while(<FH>) {
		if($_ =~ /$localdomain:$user:/) {
			$strPW = $';
			if($strPW =~ /:/) { $strPW = $`; }
			if($pass eq $strPW) {
				print "Set-Cookie: Cun=${user};\nSet-Cookie: Cpw=${pass}\n";
				close(FH);
				return $user;
			}
		}
	}
	close(FH);
	return "";
}

sub listWWD {
	my ($dir) = @_;
	my $msg = "";
	if($dir eq "") { $dir = $query->param('dir'); }
	$dir =~ s/[^A-Za-z0-9\.\/]//g;
	$dir =~ s/\.\.//g;
	my @flist = glob "${basedir}${dir}/*";
	my @dirlist = split(/\//, $dir);
	my $thedir = "";
	$msg .= "<A HREF=\"wwdeditor.pl?dir=\">WWD</A>";
	for(my $i=1; $i<@dirlist; $i++) {
		if(($i + 1) == @dirlist) { $msg .= "::${dirlist[$i]}"; }
		else { $msg .= "::<A HREF=\"wwdeditor.pl?dir=${thedir}/${dirlist[$i]}\">${dirlist[$i]}</A>"; }
		$thedir .= "/${dirlist[$i]}";
	}
	$msg .= "<BR><BR>";
	$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
	$msg .= "<INPUT TYPE=hidden NAME=a VALUE=createdir>";
	$msg .= "<INPUT TYPE=hidden NAME=curdir VALUE=\"${thedir}\">";
	$msg .= "Create a new directory <INPUT TYPE=TEXT NAME=dir>";
	$msg .= "<INPUT TYPE=SUBMIT VALUE=GO></FORM>"; 		
	$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
	$msg .= "<INPUT TYPE=hidden NAME=a VALUE=createent>";
	$msg .= "<INPUT TYPE=hidden NAME=dir VALUE=\"${thedir}\">";
	$msg .= "Create a new entry <INPUT TYPE=TEXT NAME=name>";
	$msg .= "<INPUT TYPE=SUBMIT VALUE=GO></FORM>"; 		
	$msg .= "<TABLE>";

	for(my $i=0; $i<@flist; $i++) {
		my @frec = stat $flist[$i];
		$flist[$i] =~ s/^$basedir$dir\///;
		my $s = readlink "${basedir}/" . $flist[$i];
		if(($s eq "")&&($flist[$i] ne "cached")&&($flist[$i] ne "datastore")) {
			if($frec[2] > 30000) {
				$msg .= "<TR>";
				$msg .= "<TD><A HREF=\"wwdeditor.pl?a=editent&amp;dir=${thedir}&amp;name=${flist[$i]}\">${flist[$i]}</A></TD>";
				$msg .= "<TD><A HREF=\"wwdeditor.pl?a=delentry&amp;dir=${dir}&amp;name=${flist[$i]}\">[DELETE]</A></TD>";
				$msg .= "</TR>";
			} else {
				$msg .= "<TR>";
				$msg .= "<TD><A HREF=\"wwdeditor.pl?dir=${thedir}/${flist[$i]}\">&lt;DIR&gt;  ${flist[$i]}</TD>";
				$msg .= "<TD><A HREF=\"wwdeditor.pl?a=deldir&amp;dir=${thedir}/${flist[$i]}\">[REMOVE DIRECTORY]</A></TD>";
				$msg .= "</TR>";
			}
		}
	}
	$msg .= "</TABLE>";
	return $msg;
}

sub createDir {
	my $dir = $query->param('dir');
	my $curdir = $query->param('curdir');
	$dir =~ s/[^A-Za-z0-9\.\/]//g;
	$dir =~ s/\.\.//g;
	$curdir =~ s/[^A-Za-z0-9\.\/]//g;
	$curdir =~ s/\.\.//g;

	if(-e "${basedir}${curdir}/${dir}") { return "A file or directory by that name already exists!<BR><BR>" . listWWD("${curdir}"); }

	mkdir("${basedir}${curdir}/${dir}");
	return listWWD("${curdir}/${dir}");
}

sub deleteDir {
	my $dir = $query->param('dir');
	my $confirm = $query->param('confirm');
	$dir =~ s/[^A-Za-z0-9\.\/]//g;
	$dir =~ s/\.\.//g;

	if($dir =~ /^\//) { $dir = $'; }
	if($dir eq "") { return "I am not allowed to perform that function!"; }
	if($confirm eq "yes") {
		system("rm -rf ${basedir}/${dir}");
	} else {
		my $msg = "Are you sure you with to delete the <B><I>${dir}</I></B> directory, and it's ENTIRE contents? This action is not undoable!";
		$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=a VALUE=>";
		$msg .= "<INPUT TYPE=SUBMIT VALUE=NO></FORM>";	

		$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=a VALUE=deldir>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=dir VALUE=\"${dir}\">";
		$msg .= "<INPUT TYPE=HIDDEN NAME=confirm VALUE=yes>";
		$msg .= "<INPUT TYPE=SUBMIT VALUE=YES></FORM>";
		print $msg.$footer;
		exit;
	}
	return "";
}


sub deleteEntry {
	my $dir = $query->param('dir');
	my $name = $query->param('name');
	my $confirm = $query->param('confirm');
	$name =~ s/[^A-Za-z0-9\.\/\_\-]//g;
	$name =~ s/\.\.//g;

	if($name eq "") { return "I am not allowed to perform that function!<BR><BR>"; }
	if($confirm eq "yes") {
		system("rm ${basedir}${dir}/${name}");
	} else {
		my $msg = "Are you sure you with to delete the entry <B><I>${dir}/${name}</I></B>? This action is not undoable!";
		$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=a VALUE=>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=dir VALUE=\"${dir}\">";
		$msg .= "<INPUT TYPE=SUBMIT VALUE=NO></FORM>";	

		$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=a VALUE=delentry>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=name VALUE=\"${name}\">";
		$msg .= "<INPUT TYPE=HIDDEN NAME=dir VALUE=\"${dir}\">";
		$msg .= "<INPUT TYPE=HIDDEN NAME=confirm VALUE=yes>";
		$msg .= "<INPUT TYPE=SUBMIT VALUE=YES></FORM>";
		print $msg.$footer;
		exit;
	}
	return "";
}

sub createEntry {
	my $dir = $query->param('dir');
	my $name = $query->param('name');
	my $save = $query->param('save');
	$name =~ s/[^A-Za-z0-9\.\/\_\-]//g;
	$name =~ s/\.\.//g;
	$dir =~ s/[^A-Za-z0-9\.\/]//g;
	$dir =~ s/\.\.//g;

	if($name eq "") { return "I am not allowed to perform that function!<BR><BR>"; }
	if(-e "${basedir}${dir}/${name}") { return "That entry already exists!<BR><BR>"; }
	if($save eq "true") {
		my $value = $query->param('value');
		my $owner = $query->param('owner');
		my $mp = $query->param('mp');
		my $rp = $query->param('rp');
		my $tp = $query->param('temppw');
		my $ttl = $query->param('ttl');
		my $allowedips = $query->param('allowedips');
		$value =~ s/\r//gs;
		$value =~ s/\n$//g;
		chomp($value);
		$value =~ s/\n/\r/gs;

		if($tp =~ /\;/) {
			my $a = $`;
			my $b = $';
			my $s = eval($a + time);
			$tp = "${s};${b}";
		} else { $tp = ""; }
		open(FH,">${basedir}${dir}/${name}");
		flock(FH,LOCK_EX);
		print FH "$value\n$owner\n$mp\n$tp\n$ttl\n$rp\n$allowedips\n" . time . "\n";
		close(FH);
		return "";
	} else {
		my $msg = "You are now creating <B><I>wwd://${dir}/${name}</I></B>:";

		$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=name VALUE=\"${name}\">";
		$msg .= "<INPUT TYPE=HIDDEN NAME=a VALUE=createent>";
		$msg .= "<INPUT TYPE=HIDDEN NAME=dir VALUE=\"${dir}\">";
		$msg .= "<INPUT TYPE=HIDDEN NAME=save VALUE=true>";
		$msg .= "<TABLE>";
		$msg .= "<TR><TD valign=\"top\" colspan=\"2\">Value<br /><textarea name=\"value\" rows=\"10\" cols=\"60\"></textarea></TD></TR>";
		$msg .= "<TR><TD>Owner</TD><TD><INPUT TYPE=TEXT NAME=owner value=\"${username}\"></TD></TR>";
		$msg .= "<TR><TD>Modification password</TD><TD><INPUT TYPE=TEXT NAME=mp></TD></TR>";
		$msg .= "<TR><TD>Time to live (in seconds):temporary password</TD><TD><INPUT TYPE=TEXT NAME=temppw></TD></TR>";
		$msg .= "<TR><TD>Time to live (in seconds)</TD><TD><INPUT TYPE=TEXT NAME=ttl></TD></TR>";
		$msg .= "<TR><TD>Retrieval password</TD><TD><INPUT TYPE=TEXT NAME=rp></TD></TR>";
		$msg .= "<TR><TD>Allowed List</TD><TD><INPUT TYPE=TEXT NAME=allowedips></TD></TR>";
		$msg .= "</TABLE>";
		$msg .= "<INPUT TYPE=SUBMIT VALUE=save></FORM>";
		print $msg.$footer;
		exit;
	}
	return "";
}

sub editEntry {
	my $dir = $query->param('dir');
	my $name = $query->param('name');
	my $save = $query->param('save');
	$name =~ s/[^A-Za-z0-9\.\/\_\-]//g;
	$name =~ s/\.\.//g;
	$dir =~ s/[^A-Za-z0-9\.\/]//g;
	$dir =~ s/\.\.//g;

	my $value=$owner=$mp=$rp=$temppw=$ttl=$allowedips = "";
	if($name eq "") { return "I am not allowed to perform that function!<BR><BR>"; }
	if($save eq "true") {
		$value = $query->param('value');
		$owner = $query->param('owner');
		$mp = $query->param('mp');
		$rp = $query->param('rp');
		$tp = $query->param('temppw');
		$ttl = $query->param('ttl');
		$allowedips = $query->param('allowedips');
		$value =~ s/\r//gs;
		$value =~ s/\n$//g;
		chomp($value);
		$value =~ s/\n/\r/gs;

		if($tp =~ /\;/) {
			my $a = $`;
			my $b = $';
			my $s = eval($a + time);
			$tp = "${s};${b}";
		} else { $tp = ""; }
		open(FH,">${basedir}${dir}/${name}");
		flock(FH,LOCK_EX);
		print FH "$value\n$owner\n$mp\n$tp\n$ttl\n$rp\n$allowedips\n" . time . "\n";
		close(FH);
	}
	my $msg = "You are now editing <B><I>wwd:/${dir}/${name}</I></B>:";
	open(FH,"${basedir}${dir}/${name}");
	flock(FH,LOCK_EX);
	my @erec = <FH>;
	close(FH);
	my($s1, $s2) = split(/;/, $erec[3]);
	if($s1 ne "") {
		if($s1 < time) {
			$s1=$s2 = "";
		} else {
			$s1 -= time;
			$erec[3] = "${s1};${s2}";
		}
	}
	$erec[0] =~ s/\&/\&amp\;/g;
	$msg .= "<FORM ACTION=wwdeditor.pl METHOD=POST>";
	$msg .= "<INPUT TYPE=HIDDEN NAME=name VALUE=\"${name}\">";
	$msg .= "<INPUT TYPE=HIDDEN NAME=a VALUE=editent>";
	$msg .= "<INPUT TYPE=HIDDEN NAME=dir VALUE=\"${dir}\">";
	$msg .= "<INPUT TYPE=HIDDEN NAME=save VALUE=true>";
	$msg .= "<TABLE>";
	$msg .= "<TR><TD colspan=\"2\">Value<br /><TEXTAREA ROWS=15 COLS=60 NAME=value>${erec[0]}</TEXTAREA></TD></TR>";
	$msg .= "<TR><TD>Owner</TD><TD><INPUT TYPE=TEXT NAME=owner VALUE=\"${erec[1]}\"></TD></TR>";
	$msg .= "<TR><TD>Modification password</TD><TD><INPUT TYPE=TEXT NAME=mp VALUE=\"${erec[2]}\"></TD></TR>";
	$msg .= "<TR><TD>Time to live (in seconds);temp pw</TD><TD><INPUT TYPE=TEXT NAME=temppw VALUE=\"${erec[3]}\"></TD></TR>";
	$msg .= "<TR><TD>Time to live (in seconds)</TD><TD><INPUT TYPE=TEXT NAME=ttl VALUE=\"${erec[4]}\"></TD></TR>";
	$msg .= "<TR><TD>Retrieval password</TD><TD><INPUT TYPE=TEXT NAME=rp VALUE=\"${erec[5]}\"></TD></TR>";
	$msg .= "<TR><TD>Allowed List</TD><TD><INPUT TYPE=TEXT NAME=allowedips VALUE=\"${erec[6]}\"></TD></TR>";
	$msg .= "</TABLE>";
	$msg .= "<INPUT TYPE=SUBMIT VALUE=save></FORM>";
	$msg .= "<A HREF=\"wwdeditor.pl?dir=${dir}\">[BACK]</A>";
	print $msg.$footer;
	exit;
}
