#!/usr/bin/perl -T

#Simple CGI script to allow a user to change their password. 
use strict;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use OSS::LDAPops;

my($page);

sub header {
		print(
			$page->header,
			$page->start_html('Change Password')
		);
};

sub footer {
		print(
			$page->end_html
		);
};

sub form {
	&header;
	print(
		$page->start_form,
		$page->start_table,
		'<tr><td>Userid:</td><td>'.$page->textfield('uid').'</td></tr>',,
		'<tr><td>Old Password:</td><td>'.$page->password_field('oldpw').'</td></tr>',
		'<tr><td>New Password:</td><td>'.$page->password_field('newpw').'</td></tr>',
		'<tr><td>New Password again:</td><td>'.$page->password_field('newpwa').'</td></tr>',
		$page->end_table,
		$page->submit('Change'),
		$page->end_form
	);
	&footer;
};

sub update_password {
	my($uid,$oldpw,$newpw) = @_;
	my($ldapopsobj) = OSS::LDAPops->new({
	        LDAPHOST        =>      '10.60.1.1',
		BINDDN          =>      'uid='.$uid.',ou=people, dc=auth, dc=hacknix,dc=net',
		BASEDN          =>      'dc=auth,dc=hacknix,dc=net',
		NISDOMAIN       =>      'auth.hacknix.net',
		PASSWORD        =>      $oldpw,
		});
	if (ref($ldapopsobj) !~ m/OSS::LDAPops/ ) {carp("Error instantiating object: $ldapopsobj")};
	$ldapopsobj->bind;
	my($ret) = $ldapopsobj->updatepw($uid,$newpw,0,'people');
	if ($ret) {
		&header;
		print('<strong>Password not changed, error: '.$ret.'<strong>');
		&footer;
	}
	else { 
		&header;
		print('<strong> password changed</strong>');
		&footer;
	};
};


sub main {
	$page = CGI->new;
	if ($page->param('uid') and $page->param('oldpw') and $page->param('newpw') and $page->param('newpwa')) {
		if ($page->param('newpw') eq $page->param('newpwa')) {
			&update_password($page->param('uid'),$page->param('oldpw'),$page->param('newpw'))
		} else {
			&header;
			print('<strong>New passwords do not match<strong>');
			&footer;

		};
	}
	else {&form;};

};
&main
