#!/usr/bin/perl
=head1 NAME

ldapops.pl - perform operations on an LDAP directory from the command line

=head1 SYNOPISIS

Perform operations on the OSS ldap directory

This code uses the module for OSS directory actions, "OSS::LDAPops." Please see OSS::LDAPops for more details. 

This program will return nothing on sucess and will die with
an error message to STDERR on fail. 

All operations required to administer the directory are avaliable
via this program apart from changing objects outside of the user and group
space. These must be altered manuaelly. 

This code does not have to run on the LDAP server as it is network enabled
and can be used over the network from a suitable location, ACL permitting of course!

=head1 CONFIG

A configuration file is required in /etc/ldapops.conf or ~/.ldapopsrc. An example is below:

	$GLOBAL::config =
	{
		LDAPHOST	=>	'ldap01.mydomain.net',
		BINDDN		=>	'uid=webportal, ou=writeaccess, dc=auth, dc=mydomain,dc=net',
		BASEDN		=> 	'dc=auth,dc=mydomain,dc=net',
		NISDOMAIN	=>	'auth.mydomain.net',
		PASSWORD	=>	'xyzzy',
	};

	#These config options are used within this script
	$GLOBAL::localconfig =
	{
		SHADOWMAX	=>	90,
		SHADOWMIN	=>	10,
		SHADOWWARNING	=>	10,
		SHELL		=>	'/bin/bash',
		#Trailing '/' please!
		HOMEPREFIX	=>	'/home/',
		GID		=>	300
	};

	#This 1 is required!
	1;

This example file is also included in the source distribution. 

=head1 USAGE

	ldapops.pl -su <string>                       | search user
	ldapops.pl -sg <string>                       | search netgroup
	ldapops.pl -sx <string>                       | search unix/posix group
	ldapops.pl -ah <hostname>                     | add host
	ldapops.pl -ahg <group>                       | add hostgroup
	ldapops.pl -aug <user>                        | add usergroup
	ldapops.pl -axg <group> <gid>                 |add unix/posix group
	ldapops.pl -auug <userid> <group>             | add user to user group
	ldapops.pl -duug <userid> <group>             | delete user from user group
	ldapops.l -auh <userid> <host>               | add user to host
	ldapops.pl -duh <userid> <host>               | delete user from host
	ldapops.pl -ahhg <host> <group>               | add host to host group
	ldapops.pl -dhhg <host> <group>               | delete host from host group
	ldapops.pl -augug <addgroup> <togroup>        | add user group to user group
	ldapops.pl -dugug <delgroup> <fromgroup>      | delete user group from user group
	ldapops.pl -ahghg <addgroup> <togroup>        | add host group to host group
	ldapops.pl -dhghg <delgroup> <fromgroup>      | delete host group from host group
	ldapops.pl -aung <userid> <unix group>        | add user to unix group
	ldapops.pl -dung <userid> <unix group>        | del user from unix group
	ldapops.pl -au                                | add user
	ldapops.pl -up <userid> <password>            | update password for user
	ldapops.pl -upr <userid> <password>           | update password for user and force reset on next login
	ldapops.pl -upo <userid> <password> <ou>      | update password for user in non-standard ou
	ldapops.pl -b <csv file>                      | batch add users from CSV file (see batchadd.csv for format)
	ldapops.pl -d '<dn>'                          | delete dn (note the quotes)

Note: the wildcard '*' can be used, but must be escaped as \*


=cut
BEGIN
{
        unshift(@INC, './lib/');
	        };

#use strict pragma.
use strict;

#Use OSS::LDAPops object. 
use OSS::LDAPops 1.033;

warn ("Your OSS::LDAPops is version $OSS::LDAPops::VERSION. This version lf ldapops.pl is designed\nto work with 1.0.33. Upgrade this script!\n") unless ($OSS::LDAPops::VERSION == 1.033);

#Use file operations
use OSS::Fileops;

#Load config

if (-r "$ENV{HOME}/.ldapopsrc")
{
	require "$ENV{HOME}/.ldapopsrc";
}
else
{
	require '/etc/ldapops.conf'
};
#Instantiate new object.
my($ldapopsobj);
if ($ARGV[0]) {
	$ldapopsobj = OSS::LDAPops->new($GLOBAL::config);
	if (ref($ldapopsobj) !~ m/OSS::LDAPops/ ) {die("Error instantiating object: $ldapopsobj")}; 
};
my($ret);
my(@retu);
#If argument x received....
#Search for user
if ($ARGV[0] eq '-su')
{
	if (!$ARGV[1]) 
	{
		print("\nUsage: ldaops.pl -su <search string>\n");
		exit;
	};
	$ldapopsobj->bind;
	@retu = $ldapopsobj->searchuser($ARGV[1]);
	die($retu[0]) if (($retu[0] ne undef) and (ref($retu[0]) !~ m/Net::LDAP::Entry/) );
	foreach my $entry (@retu) {$entry->dump; }
	#if($ret) {die($ret);};
	exit;
}
#Search for netgroup 
elsif ($ARGV[0] eq '-sg')
{
	if (!$ARGV[1]) 
	{
		print("\nUsage: ldaops.pl -sg <search string>\n");
		exit;
	};
	$ldapopsobj->bind;
	@retu = $ldapopsobj->searchnetgroup($ARGV[1]);
	die($retu[0]) if (($retu[0] ne undef) and (ref($retu[0]) !~ m/Net::LDAP::Entry/) );
	foreach my $entry (@retu) {$entry->dump; }
	exit;
}
#Search for unix group
elsif ($ARGV[0] eq '-sx')
{
	if (!$ARGV[1]) 
	{
		print("\nUsage: ldaops.pl -sx <search string>\n");
		exit;
	};
	$ldapopsobj->bind;
	@retu = $ldapopsobj->searchunixgroup($ARGV[1]);
	die($retu[0]) if (($retu[0] ne undef) and (ref($retu[0]) !~ m/Net::LDAP::Entry/) );
	foreach my $entry (@retu) {$entry->dump; }
	exit;
}
#Add host user group
elsif ($ARGV[0] eq '-ah')
{
	if (!$ARGV[1])
	{
		print("\nUsage: ldapops.pl -ah <hostname>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addhost($ARGV[1]);
	if($ret) {die($ret);};
	exit;
}
#Add host group
elsif ($ARGV[0] eq '-ahg')
{
	if (!$ARGV[1])
	{
		print("\nUsage: ldapops.pl -ahg <group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addhostgroup($ARGV[1]);
	if($ret) {die($ret);};
	exit;
}
#Add user group
elsif ($ARGV[0] eq '-aug')
{
	if (!$ARGV[1])
	{
		print("\nUsage: ldapops.pl -aug <group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addusergroup($ARGV[1]);
	if($ret) {die($ret);};
	exit;
}
#Add unix group
elsif ($ARGV[0] eq '-axg')
{
	if (!$ARGV[1] and !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -axg <group> <gid>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addunixgroup($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Add user to user group
elsif ($ARGV[0] eq '-auug')
{
	if (!$ARGV[1]or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -auug <userid> <group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addusertoug($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Delete user from user group
elsif ($ARGV[0] eq '-duug')
{
	if (!$ARGV[1]or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -auug <userid> <group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->deluserfromug($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Add host to host group
elsif ($ARGV[0] eq '-ahhg')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -ahhg <host> <group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addhosttohg($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Delete host from host group
elsif ($ARGV[0] eq '-dhhg')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -ahhg <host> <group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->delhostfromhg($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Add user group to user group
elsif ($ARGV[0] eq '-augug')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -augug <addgroup> <togroup>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addgrouptogroup('ug',$ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Del ug from ug
elsif ($ARGV[0] eq '-dugug')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -augug <delgroup> <fromgroup>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->delgroupfromgroup('ug',$ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#add hg to hg
elsif ($ARGV[0] eq '-ahghg')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -augug <addgroup> <togroup>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addgrouptogroup('hg',$ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Del hg from hg
elsif ($ARGV[0] eq '-dhghg')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -augug <delgroup> <fromgroup>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->delgroupfromgroup('hg',$ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#add user to host user group
elsif ($ARGV[0] eq '-auh')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -auh <userid> <host>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addusertohug($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Delete user from host user group
elsif ($ARGV[0] eq '-duh')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -auh <userid> <host>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->deluserfromhug($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}

#Add user to unix group
elsif ($ARGV[0] eq '-aung')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -aung <userid> <unix group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->addusertounixgroup($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Delete user from unix group
elsif ($ARGV[0] eq '-dung')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -aung <userid> <unix group>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->deluserfromunixgroup($ARGV[1],$ARGV[2]);
	if($ret) {die($ret);};
	exit;
}
#Update passworf for user
elsif ($ARGV[0] eq '-up')
{
	if (!$ARGV[1] or !$ARGV[2])
	{
		print("\nUsage: ldapops.pl -up <userid> <password>\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->updatepw($ARGV[1],$ARGV[2],0,'people');
	if($ret) {die($ret);};
	exit;
}
#Update passworf for user and force reset on next login
elsif ($ARGV[0] eq '-upr')
{
        if (!$ARGV[1] or !$ARGV[2])
        {
                print("\nUsage: ldapops.pl -upr <userid> <password>\n");
                exit;
        };
        $ldapopsobj->bind;
        $ret = $ldapopsobj->updatepw($ARGV[1],$ARGV[2],1,'people');
        if($ret) {die($ret);};
        exit;
}
#Lock account
elsif ($ARGV[0] eq '-la')
{
        if (!$ARGV[1])
        {
                print("\nUsage: ldapops.pl -la <userid>\n");
                exit;
        };
        $ldapopsobj->bind;
        $ret = $ldapopsobj->lockacct($ARGV[1],1);
        if($ret) {die($ret);};
}
#Unlock account
elsif ($ARGV[0] eq '-ua')
{
        if (!$ARGV[1])
        {
                print("\nUsage: ldapops.pl -ua <userid>\n");
                exit;           
        };      
        $ldapopsobj->bind;                              
        $ret = $ldapopsobj->lockacct($ARGV[1],0);
        if($ret) {die($ret);};                                          
}   
#Update password in non-standard ou
elsif ($ARGV[0] eq '-upo')
{
        if (!$ARGV[1] or !$ARGV[2] or !$ARGV[3])
        {
                print("\nUsage: ldapops.pl -upr <userid> <password> <ou>\n");
                exit;
        };
        $ldapopsobj->bind;
        $ret = $ldapopsobj->updatepw($ARGV[1],$ARGV[2],0, $ARGV[3]);
        if($ret) {die($ret);};
        exit;
}

#Add user
elsif ($ARGV[0] eq '-au')
{
	print("\nAdd User:\n\nUsername:");
	my($uid,$givenname,$sn,$mail,$pw,$cn,$gid,$homedir,$loginshell,$employeenumber);
	$uid = <STDIN>;
	chomp($uid);
	print("\nFirst name:");
	$givenname = <STDIN>;
	chomp($givenname);
	print("\nSurname:");
	$sn = <STDIN>;
	chomp($sn);
	print("\nEmail address:");
	$mail = <STDIN>;
	chomp($mail);
	print("\nEmployee Number:");
	$employeenumber = <STDIN>;
	chomp($employeenumber);
	print("\nNumeric GID or enter for default [$$GLOBAL::localconfig{GID}]:");
	$gid = <STDIN>;
	chomp($gid);
	if ($gid !~ /^\d+/)
	{
		$gid = $$GLOBAL::localconfig{GID};
	};
	print("\nPassword:");
	$pw = <STDIN>;
	chomp($pw);
	$ldapopsobj->bind;
	$ret = $ldapopsobj->adduser($uid,$givenname,$sn,$givenname.' '.$sn,$mail,$pw,$gid,$$GLOBAL::localconfig{HOMEPREFIX}.$uid,$$GLOBAL::localconfig{SHELL},$$GLOBAL::localconfig{SHADOWMAX},$$GLOBAL::localconfig{SHADOWMIN},$$GLOBAL::localconfig{SHADOWWARNING},$$GLOBAL::localconfig{SHADOWINACTIVE},$employeenumber,$$GLOBAL::localconfig{MAILMESSAGESTORE}.$mail.'/.maildir/');
	if($ret) {die($ret);};
	exit;
}
#Batch add users
elsif ($ARGV[0] eq '-b')
{
	if (!$ARGV[1])
        {
                print("\nUsage: ldapops.pl -upr <csv file>\n");
                exit;
        };
        my($fileobj) = OSS::Fileops->new;
	my(@csvfile) = $fileobj->read_file($ARGV[1]);
	if (shift(@csvfile) !~ /^username,given name,surname,email,employeenumber,password, numeric gid/)
	 {
		die("'Error: CSV headings incorrect");

	 }
	$ldapopsobj->bind;
	my(@linesplit);
	foreach my $line (@csvfile)
	{
		chomp($line);
		@linesplit = split(/,/,$line);
		my($ret) = $ldapopsobj->adduser($linesplit[0],$linesplit[1],$linesplit[2],$linesplit[1].' '.$linesplit[2],$linesplit[3],$linesplit[5],$linesplit[6],$$GLOBAL::localconfig{HOMEPREFIX}.$linesplit[0],$$GLOBAL::localconfig{SHELL},$$GLOBAL::localconfig{SHADOWMAX},$$GLOBAL::localconfig{SHADOWMIN},$$GLOBAL::localconfig{SHADOWWARNING},$$GLOBAL::localconfig{SHADOWINACTIVE},$linesplit[4],$$GLOBAL::localconfig{MAILMESSAGESTORE}.$linesplit[7].'/.maildir/');
		if($ret) {print("User $linesplit[0] not added: $ret\n");};
	
	};
	exit;
}
#Delete DN
elsif ($ARGV[0] eq '-d')
{	
	if (!$ARGV[1])
	{
		print("\nUsage: ldapops.pl -d \'<dn>\'\n");
		exit;
	};
	$ldapopsobj->bind;
	$ret = $ldapopsobj->deletedn($ARGV[1]);
	if($ret) {die($ret);};
}
else 
#Print usage information 
{
	print("\nUsage:\n\nldapops.pl -su <string>\t\t\t\t| search user\n");
	print("ldapops.pl -sg <string>\t\t\t\t| search netgroup\n");
	print("ldapops.pl -sx <string>\t\t\t\t| search unix/posix group\n");
	print("ldapops.pl -ah <hostname>\t\t\t| add host\n");
	print("ldapops.pl -ahg <group>\t\t\t\t| add hostgroup\n");
	print("ldapops.pl -aug <user>\t\t\t\t| add usergroup\n");
	print("ldapops.pl -axg <group> <gid> \t\t\t| add unix/posix group\n");
	print("ldapops.pl -auug <userid> <group>\t\t| add user to user group\n");
	print("ldapops.pl -duug <userid> <group>\t\t| delete user from user group\n");
	print("ldapops.pl -auh <userid> <host>\t\t\t| add user to host\n");
	print("ldapops.pl -duh <userid> <host>\t\t\t| delete user from host\n");
	print("ldapops.pl -ahhg <host> <group>\t\t\t| add host to host group\n");
	print("ldapops.pl -dhhg <host> <group>\t\t\t| delete host from host group\n");
	print("ldapops.pl -augug <addgroup> <togroup>\t\t| add user group to user group\n");
	print("ldapops.pl -dugug <delgroup> <fromgroup>\t| delete user group from user group\n");
	print("ldapops.pl -ahghg <addgroup> <togroup>\t\t| add host group to host group\n");
	print("ldapops.pl -dhghg <delgroup> <fromgroup>\t| delete host group from host group\n");
	print("ldapops.pl -aung <userid> <unix group>\t\t| add user to unix group\n");
	print("ldapops.pl -dung <userid> <unix group>\t\t| del user from unix group\n");
	print("ldapops.pl -au \t\t\t\t\t| add user\n");
	print("ldapops.pl -up <userid> <password>\t\t| update password for user\n");
	print("ldapops.pl -upr <userid> <password>\t\t| update password for user and force reset on next login\n");
	print("ldapops.pl -upo <userid> <password> <ou>\t| update password for user in non-standard ou\n");
	print("ldapops.pl -la <userid>\t\t\t\t| Lock (expire) user account\n");
	print("ldapops.pl -ul <userid>\t\t\t\t| unlock user accout\n");
	print("ldapops.pl -b <csv file> \t\t\t| batch add users from CSV file (see batchadd.csv for format)\n");
	print("ldapops.pl -d \'<dn>\'\t\t\t\t| delete dn (note the quotes)\n");
	print("\nNote: the wildcard \'*\' can be used, but must be escaped as \\*\n");

};
