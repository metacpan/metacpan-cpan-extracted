=head1 NAME

OSS::LDAPops - Perform operations on user accounts, groups and netgroups stored in an LDAP directory

=head1 SYSNOPSIS

	#Define config hash
	$GLOBAL::config = 
	{
		LDAPHOST	=>	'ldap01.mydomain.net',
		BINDDN		=>	'uid=webportal, ou=writeaccess, dc=auth, dc=mydomain,dc=net',
		BASEDN		=> 	'dc=auth,dc=mydomain,dc=net',
		NISDOMAIN	=>	'auth.mydomain.net',
		PASSWORD	=>	'xyzzy',
	};
	#Instantiate new object and connect to server
	my($ldapopsobj) = OSS::LDAPops->new($GLOBAL::config);
	if (ref($ldapopsobj) !~ m/OSS::LDAPops/ ) {die("Error instantiating object: $ldapopsobj")}; 
	my($ret);
	my(@retu);
	
	#Bind server
	$ldapopsobj->bind;
	@retu = $ldapopsobj->searchuser($ARGV[1]);
	die($retu[0]) if (($retu[0] ne undef) and (ref($retu[0]) !~ m/Net::LDAP::Entry/) );
	foreach my $entry (@retu) {$entry->dump; }
	#if($ret) {die($ret);};
	exit;

=head1 DESCRIPTION

This module manipulates user, group and netgroup objects within an LDAP directory. 

Also included is ldapops.pl. This script implements a command-line utility using
OSS::LDAPops.

netgroupcache.pl is also included. This uses OSS::LDAPops to create a local cache of 
LDAP-backed netgroups in /etc/netgroup.

=head1 AUTHOR

Simon <simon@hacknix.net>

=head1 ASSUMPTIONS ABOUT THE DIRECTORY

This module and associated sripts make some assumptions about how your directory is
configured. these include:

=over 

=item * 

Storage of maxuid

=item *

Conventions for use of netgroups

=item *

nis.schema is patched to allow equalityMatch on nisNetgroupTriple objects

=back

=head1 FILES TO HELP WITH SETTING UP A DIRECTORY

In the "examples" directory, there are several files to help you out, including:

=over

=item *

An example skeleton directory. 

=item *

A patched version of nis.schema, suitable for use with OpenLDAP

=item *

An example of OpenLDAP's slapd.conf, showing example acls

=item *

changepassword.pl - an example simple CGI script using OSS::LDAPops

=item *

notifypasswordexpiry.pl - a script to send an email to users when their password expires.

=item *

ppolicy.ldif - an example password policy to use with the ppolicy overlay. 

=item *

Several other example files, to asisst in setting up *NIX servers to use the directory are also included. 

=back

=head1 USING THE DIRECTORY WITH *NIX SERVERS

The reader should consider looking at nss_ldap and pam_ldap, here:

http://www.padl.com/Contents/OpenSourceSoftware.html

=head1 METHODS

This section describes the methods that are implemented and their use. 

=head2 new

	#Define config hash
	$GLOBAL::config = 
	{
		LDAPHOST	=>	'ldap01.mydomain.net',
		BINDDN		=>	'uid=webportal, ou=writeaccess, dc=auth, dc=lastminute,dc=com',
		BASEDN		=> 	'dc=auth,dc=mydomain,dc=net',
		NISDOMAIN	=>	'auth.mydomain.net',
		PASSWORD	=>	'xyzzy',
	};
	#Instantiate new object and connect to server
	my($ldapopsobj) = OSS::LDAPops->new($GLOBAL::config);
	if (ref($ldapopsobj) !~ m/OSS::LDAPops/ ) {die("Error instantiating object: $ldapopsobj")}; 
	
Instantiates an object and connects to the LDAP server. Returns an object on success and false on error.

=cut

#Define version
$OSS::LDAPops::VERSION = '1.033';



#Please also note, proper error checking MUST be used to ensure
#the integrity of the directory.
#
#Most of the methods in this package return 0 on sucess 
#and an error string on fail. 
#
#You can therefore test for truth of the return. The string
#describes the error. 
#
#Exceptions to this are described in the comments for the methods
#themselves. 
#
#The only exceptions to this are the new() method, which returns an object
#or false on error and the salt() method which only ever returns a salt. 
#
#********N.B.***********
#
#A change to the file /etc/openldap/nis.schema is required to make 
#deleting of single entries from nisNetgroupTriple attributes within nisNetgroups
#work.
#
#This is to allow equality matching on these attributes. 

use strict;

package OSS::LDAPops;

use Net::LDAP;
use Digest::SHA1;
use MIME::Base64;

#New object
#
##requires the config hash to be passed.
#(see example in ldapops.pl)
#
#Returns an object of OSS::LDAPops on success
#and flase on error. 
sub new
{
	my($class) = shift;
	my($self) = shift;
	bless($self, $class);
	$self->{LDAPOBJ} = Net::LDAP->new($self->{LDAPHOST},debug => 0) or return($@);
	return('binddn missing') if (!$self->{BINDDN});
	return('basedn missing') if (!$self->{BASEDN});
	return('nisdomain missing') if (!$self->{NISDOMAIN});
	return('password missing') if (!$self->{PASSWORD});
	return($self);

};

=head2 bind

Bind to LDAP server with supplied credentials. 

No arguments are accepted as the pre-supplied config
values are used.

=cut
sub bind
{
	my($self) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->bind(
				$self->{BINDDN},
				password => $self->{PASSWORD}
				);
	$msg->code && return ($msg->error);
};

=head2 groupexists

Check to see if a group exists. 
	
	
	$obj->groupexists(<group>);
	
Returns 0 when the group does not exist.
Returns 2 when the group does exists.
Returns a text string on error. 

=cut
sub groupexists
{
	my($self) = shift;
	my($group) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->search( 
				base 	=> 'ou=netgroups,'.$self->{BASEDN},
				scope 	=> 'one',
				filter	=> "(cn=$group)",
				);
	$msg->code && return ($msg->error);
	if ($msg->entries) {return(2)}
	else {return(0);};
};

=head2 userexists

Check if user exists. 
	
	$obj->userexists(<user>);

Returns 0 when the group does not exist.
Returns 2 when the group does exists.
Returns a text string on error. 

=cut
sub userexists
{
	my($self) = shift;
	my($user) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->search( 
				base 	=> 'ou=people,'.$self->{BASEDN},
				scope 	=> 'one',
				filter	=> "(uid=$user)",
				);
	$msg->code && return ($msg->error);
	if ($msg->entries) {return(2)}
	else {return(0);};
};

=head2 searchuser

Search for a users entry in the directory.
	
	$obj->searchuser(<userid>);

(the wildcard * can be used)
	
Returns an array of Net::LDAP:Entry objects on success
Returns false on no results. 
Returns an error string on error. 

=cut
sub searchuser
{
	my($self) = shift;
	my($userid) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->search( 
				base 	=> 'ou=people,'.$self->{BASEDN},
				scope 	=> 'one',
				filter	=> "(uid=$userid)",
				);
	$msg->code && return ($msg->error);
	return($msg->entries);


};

=head2 searchnetgroup

Search for a netgroup entry in the directory.

	#$obj->searchnetgroup(<group>);

(the wildcard * can be used)
	
Returns an array of Net::LDAP:Entry objects on success
Returns false on no results. 
Returns an error string on error. 

=cut
sub searchnetgroup
{
	my($self) = shift;
	my($srch) = shift;
	my($msg);
        $msg = $self->{LDAPOBJ}->search(
				base    => 'ou=netgroups,'.$self->{BASEDN},
				scope   => 'one',
				filter  => "(cn=$srch)"
				);
	$msg->code && ($msg->error);
	return($msg->entries);
	#foreach my $entry ($msg->entries) {$entry->dump;};

};


=head2 searchunixgroup

Search for a unix (posix) group  entry in the directory.

	#$obj->searchunixgroup(<group>);

(the wildcard * can be used)
	
Returns an array of Net::LDAP:Entry objects on success
Returns false on no results. 
Returns an error string on error. 

=cut
sub searchunixgroup
{
	my($self) = shift;
	my($srch) = shift;
	my($msg);
        $msg = $self->{LDAPOBJ}->search(
				base    => 'ou=unixgroups,'.$self->{BASEDN},
				scope   => 'one',
				filter  => "(cn=$srch)"
				);
	$msg->code && ($msg->error);
	return($msg->entries);
	#foreach my $entry ($msg->entries) {$entry->dump;};

};

=head2 addhost

Add a host entry to the directory
	
	$obj->addhost(<hostname>);

Returns a text string on error
Returns false on success

=cut
sub addhost
{
	my($self) =shift;
	my($hostname) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->add(
				"cn=$hostname-hug, ou=netgroups,".$self->{BASEDN},
				attr	=> [
					'cn'		=>	$hostname.'-hug',
					'description'	=>	"Host User Group for $hostname",
					'objectclass'	=>	['top','nisNetgroup']
					]
				);
	$msg->code && return ($msg->error);

};

=head2 addhostgroup

Add a host group entry to the directory
	
	$obj->addhostgroup(<hostname>);
	
Returns a text string on error
Returns false on success

=cut
sub addhostgroup
{
	my($self) =shift;
	my($hostname) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->add(
				"cn=$hostname-hg, ou=netgroups,".$self->{BASEDN},
				attr	=> [
					'cn'		=>	$hostname.'-hg',
					'description'	=>	"Host Group for $hostname",
					'objectclass'	=>	['top','nisNetgroup']
					]
				);
	$msg->code && return ($msg->error);

};

=head2 addusergroup

Add a user group entry to the directory
	
	$obj->addusergroup(<groupname>);
	
Returns a text string on error
Returns false on success

=cut
sub addusergroup
{
	my($self) =shift;
	my($groupname) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->add(
				"cn=$groupname-ug, ou=netgroups,".$self->{BASEDN},
				attr	=> [
					'cn'		=>	$groupname.'-ug',
					'description'	=>	"User Group: $groupname",
					'objectclass'	=>	['top','nisNetgroup']
					]
				);
	$msg->code && return ($msg->error);

};

=head2 addunixgroup

Add a unix group to the directory

	$obj->addunixgroup(<groupname>,<gid>);

returns a text string on error
returns false on success
=cut
sub addunixgroup
{
        my($self) =shift;
        my($groupname) = shift;
	my($gid) = shift;
        my($msg);
        $msg = $self->{LDAPOBJ}->add(
                                "cn=$groupname, ou=unixgroups,".$self->{BASEDN},
                                attr    => [
                                        'cn'            =>      $groupname,
                                        'description'   =>      "Unix Group: $groupname",
                                        'objectclass'   =>      ['top','posixGroup'],
					'gidNumber'		=>	$gid
                                        ]
                                );
        $msg->code && return ($msg->error);

};

#Generate salt for SHA1. 
sub salt8 {
      	my($self) = shift;
	my $salt = join '', ('a'..'z')[rand 26,rand 26,rand 26,rand 26,rand 26,rand 26,rand 26,rand 26];
	return($salt);
}


sub password_ssha {
        my($self) = shift;
	my $pass=shift;
        my ($hashedPasswd,$salt);
        $salt = &salt8;
        my $ctx = Digest::SHA1->new;
        $ctx->add($pass);
        $ctx->add($salt);
        $hashedPasswd = '{SSHA}' . encode_base64($ctx->digest . $salt,'');
        return($hashedPasswd);
}

=head2 adduser

Add a user entry to the directory
	
	$obj->adduser(<username>);
	
Returns a text string on error
Returns false on success

=cut
sub adduser
{
	
	my($self) = shift;
	my($uid, $givenname, $sn, $cn, $mail, $password, $gid, $homedir, $loginshell,$shadowmax, $shadowmin, $shadowwarn, $shadowinactive, $employeenumber,$mailmessagestore) = @_;
	my($msg);
	srand;
	my($salt) = $self->salt8;

	$msg = $self->{LDAPOBJ}->search( 
				base 	=> 'uid=maxUid,'.$self->{BASEDN},
				scope 	=> 'sub',
				filter	=> "(uid=maxUid)"
				);
	$msg->code && return ($msg->error);
	my($entry) = $msg->entry;
	return('Problem: could maxUid be missing from the directory?') if (!$entry);
	my($maxuid) = $entry->get_value('uidNumber');
	my($newmaxuid);
	my($i) = 0;
	until ($i)
	{
		 $newmaxuid = $maxuid+1;
		 $msg = $self->{LDAPOBJ}->modify( 
				"uid=maxUid,".$self->{BASEDN},
				delete	=> {
						'uidNumber' => $maxuid
					},
				add	=> {
						'uidNumber' => $newmaxuid
				}
				);
		$msg->code && next;
		$i++;
	};
	$msg = $self->{LDAPOBJ}->add(
				"uid=$uid, ou=people,".$self->{BASEDN},
				attr	=> [
					'uid'		=>	$uid,
					'uidNumber'	=>	$newmaxuid,
					'cn'		=>	$cn,
					'givenname'	=>	$givenname,
					'sn'		=>	$sn,
					'mail'		=>	$mail,
					'gidNumber'	=>	$gid,
					'homeDirectory'	=>	$homedir,
					'loginshell'	=>	$loginshell,
					'userpassword'	=>	$self->password_ssha($password,$salt),
					'description'	=>	"User entry for $cn - $uid",
					'objectclass'	=>	['top','person','inetOrgPerson','posixAccount','shadowAccount','qmailUser'],
					'shadowMax'	=>	$shadowmax,
					'shadowMin'	=>	$shadowmin,
					'shadowWarning'	=>	$shadowwarn,
					'employeeNumber'=>	$employeenumber,
					'shadowInactive'=>	$shadowinactive,
					'shadowLastChange'=>	0,
					'mailMessageStore' => $mailmessagestore
					]
				);
	$msg->code && return ($msg->error);
};



=head2 updatepw

Add a user entry to the directory
		
	$obj->updatepw(<username>,<password>,<force reset on login [1|0]>);
	
Returns a text string on error
Returns false on success

=cut
sub updatepw
{
	my($self) = shift;
	my($yw,$newpw,$forcereset,$ou) = @_;
	my($msg);
	my($salt) = $self->salt8;
	if ($forcereset)
	{
                $msg = $self->{LDAPOBJ}->modify(
                                "uid=$yw, ou=$ou,".$self->{BASEDN},
                                replace => {
                                                'userpassword' 		=> $self->password_ssha($newpw,$salt),
						'shadowLastChange' 	=> 0
                                        }
                        );

	} else
	{
		$msg = $self->{LDAPOBJ}->modify( 
				"uid=$yw, ou=$ou,".$self->{BASEDN},
				replace	=> {
						'userpassword' => $self->password_ssha($newpw,$salt)	
					}
			);
	}
	$msg->code && return ($msg->error);
};

=head2 lockacct

Lock a user account by setting shadowExpire to 1

	$obj->lockacct(<uid>,<lock [1|0]>,<ppolicy [1|0]>);


=cut

sub lockacct {
	my($self) = shift;
	my($uid) = shift;
	my($lock) = shift;
	my($useppolicy) = shift;
	my($msg);
	if ($lock)
	{
                $msg = $self->{LDAPOBJ}->modify(
                                "uid=$uid, ou=people,".$self->{BASEDN},
                                replace => {
                                                'shadowExpire' 		=> 1
                                        }
                        );

	} else
	{
		$msg = $self->{LDAPOBJ}->modify( 
				"uid=$uid, ou=people,".$self->{BASEDN},
				replace	=> {
						'shadowExpire' 		=> -1
					}
			);
	}
	$msg->code && return ($msg->error);
};

=head2 addusertoug

Add a user entry to a user group

	$obj->addusertoug(<username>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub addusertoug
{
	my($self) = shift;
	my($yw,$group) = @_;
	my($msg);
	my ($ue) = $self->userexists("$yw");
	return ('User to add does not exist') if (!$ue);
	return($ue) if ($ue ne '2');
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$group-ug, ou=netgroups,".$self->{BASEDN},
				add	=> {
						'nisNetgroupTriple' => "(,$yw,$self->{NISDOMAIN})"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 deluserfromug

Del a user from a user gorup

	$obj->deluserfromug(<username>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub deluserfromug
{
	my($self) = shift;
	my($yw,$group) = @_;
	my($msg);
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$group-ug, ou=netgroups,".$self->{BASEDN},
				delete	=> {
						'nisNetgroupTriple' => "(,$yw,$self->{NISDOMAIN})"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 addhosttohg

Add a host to a host group
	
	$obj->addhosttohg(<host>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub addhosttohg
{
	my($self) = shift;
	my($host,$group) = @_;
	my($msg);
	my ($he) = $self->groupexists("$host-hug");
	return ('Host to add does not exist') if (!$he);
	return($he) if ($he ne '2');
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$group-hg, ou=netgroups,".$self->{BASEDN},
				add	=> {
						'nisNetgroupTriple' => "($host,,$self->{NISDOMAIN})"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 delhostfromhg

Delete host from host group
	
	$obj->delhostfromhg(<host>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub delhostfromhg
{
	my($self) = shift;
	my($host,$group) = @_;
	my($msg);
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$group-hg, ou=netgroups,".$self->{BASEDN},
				delete	=> {
						'nisNetgroupTriple' => "($host,,$self->{NISDOMAIN})"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 addusertohug

add user to host user group
	
	$obj->addusertohug(<host>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub addusertohug
{
	my($self) = shift;
	my($yw,$host) = @_;
	my($msg);
	my ($ue) = $self->userexists("$yw");
	return ('User to add does not exist') if (!$ue);
	return($ue) if ($ue ne '2');
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$host-hug, ou=netgroups,".$self->{BASEDN},
				add	=> {
						'nisNetgroupTriple' => "($host,$yw,$self->{NISDOMAIN})"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 deluserfromhug

delete user from host user group
	
	$obj->deluserfromhug(<host>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub deluserfromhug
{
	my($self) = shift;
	my($yw,$host) = @_;
	my($msg);
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$host-hug, ou=netgroups,".$self->{BASEDN},
				delete	=> {
						'nisNetgroupTriple' => "($host,$yw,$self->{NISDOMAIN})"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 addgrouptogroup

Add a group to a group

	$obj->addggrouptogroup(<ug|hg>,<host>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub addgrouptogroup
{
	my($self) = shift;
	my($type,$addgroup,$togroup) = @_;
	return('Type not ug or hg') if ($type !~ m/[uh]g/);
	return('Cannot add a group to itself') if ($addgroup eq $togroup);
	my ($ge) = $self->groupexists("$addgroup-$type");
	return ('Group to add does not exist') if (!$ge);
	return($ge) if ($ge ne '2');
	my($msg);
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$togroup-$type, ou=netgroups,".$self->{BASEDN},
				add	=> {
						'memberNisNetgroup' => "$addgroup-$type"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 delgroupfromgroup

delete group from group

	$obj->delgroupfromgroup(<ug|hg>,<host>,<group>);
	
Returns a text string on error
Returns false on success

=cut
sub delgroupfromgroup
{
	my($self) = shift;
	my($type,$delgroup,$fromgroup) = @_;
	return('Type not ug or hg') if ($type !~ m/[uh]g/);
	my($msg);
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$fromgroup-$type, ou=netgroups,".$self->{BASEDN},
				delete	=> {
						'memberNisNetgroup' => "$delgroup-$type"	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 addusertounixgroup

add user to a unix group

        $obj->addusertounixgroup(<user>,<unix group>);
	        
Returns a text string on error
Returns false on success

=cut

sub addusertounixgroup
{
	my($self) = shift;
	my($user,$group) = @_;
	my($msg);
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$group, ou=unixgroups,".$self->{BASEDN},
				add	=> {
						'memberUid' => $user	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 deluserfromunixgroup

delete user from a unix group

        $obj->deluserfromunixgroup(<user>,<unix group>);
	        
Returns a text string on error
Returns false on success

=cut

sub deluserfromunixgroup
{
	my($self) = shift;
	my($user,$group) = @_;
	my($msg);
	$msg = $self->{LDAPOBJ}->modify( 
				"cn=$group, ou=unixgroups,".$self->{BASEDN},
				delete	=> {
						'memberUid' => $user	
					}
				);
	$msg->code && return ($msg->error);
};

=head2 deletedn

Delete an entry by DN (use with caution)
	
Used to remove users and groups by DN
	
WARNING: it's possible to damage the tree stucture
this way!!!! get it right!!
	
	$obj=>deletedn($dn);
	
Returns a text string on error. 
Returns false on success

=cut
sub deletedn
{
	my($self) = shift;
	my($dn) = shift;
	my($msg);
	$msg = $self->{LDAPOBJ}->delete($dn);
	$msg->code && return ($msg->error);
};
#Do not remove the below '1'. It is needed for correct functioning. 
1;

#EOF

