#!/usr/bin/perl 

use strict;

use OSS::LDAPops;
use MIME::Lite;
use Sys::Syslog;

#require '/etc/ldapops.conf';

my($URL) = 'http://example.net.cgi-bin/changepassword.pl';

sub send_mail {
	my($to) = shift;
	my($name) = shift;
	my($uid) = shift;
	my(@email) = "Dear $name, \n\nYour password for user ID $uid has expired. Please visit the link below to change it.\n\n$URL\n\nNote, if you do not change your password soon, your account will be disabled.\n\nRegards\n\nroot";
        my($mailobj) = MIME::Lite->new(
                                From    =>      $to,
                                To      =>      'simon@hacknix.net',
                                Subject =>      'Password expiry notification',
                                Type    =>      'text/plain',
                                Data    =>      \@email
                                );
        eval { $mailobj->send('smtp','mina.hacknix.net', Debug=>0 ); } or warn('Could not send email to'.$to.".\n");
};

my($epochdays) = int(time)/86400;

my($ldapopsobj) = OSS::LDAPops->new({
					LDAPHOST        =>      'ldap.example.net',
				        BINDDN          =>      'uid=webportal, ou=writeaccess, dc=auth, dc=example,dc=net',
				        BASEDN          =>      'dc=auth,dc=example,dc=net',
		        		NISDOMAIN       =>      'auth.example.net',
				        PASSWORD        =>      'example'
				});
if (ref($ldapopsobj) !~ m/OSS::LDAPops/ ) {die("Error instantiating object: $ldapopsobj")};

$ldapopsobj->bind;
my(@retu) = $ldapopsobj->searchuser('*');
die($retu[0]) if (($retu[0] ne undef) and (ref($retu[0]) !~ m/Net::LDAP::Entry/) );

foreach my $entryobj (@retu) {
	my($slc) = $entryobj->get_value('shadowLastChange');
	$epochdays = int($epochdays);
	if ($slc and ($epochdays - $slc > 90)) {
		my($email) = $entryobj->get_value('mail');
		my($name) = $entryobj->get_value('givenName');
		my($uid) = $entryobj->get_value('uid');
		print("days since change: ",$epochdays - $slc," uid: ", $uid," ");
		print("email: $email gn: $name\n");
		&send_mail($email,$name,$uid);
		&syslog('info',"user $uid notified of password expiry");
	};

};
