package Net::LDAP::posixAccount;

use warnings;
use strict;
use Net::LDAP::Entry;
use Sys::User::UIDhelper;
use Sys::Group::GIDhelper;

=head1 NAME

Net::LDAP::posixAccount - Creates new Net::LDAP::Entry objects for a posixAccount entry.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::LDAP::posixAccount;

    #Initiates the module with a base DN of 'ou=users,dc=foo'.
    my $foo = Net::LDAP::posixAccount->new({baseDN=>'ou=user,dc=foo'});

    #creates a new entry with the minimum requirements
    my $entry = $foo->create({name=>'vvelox', gid=>'404', uid=>'404'});

    #add it using $ldap, a previously created Net::LDAP object
    $entry->update($ldap);

=head1 FUNCTIONS

=head2 new

This initiates the module. It accepts one arguement, a hash. Please See below
for accepted values.

=head3 baseDN

This is a required value and is the base that the entry will be created under.

=head3 topless

This is a perl boolean value. If this is set to true, the objectClass top is
not present.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#returns undef if the baseDN is not set
	if (!defined($args{baseDN})) {
		warn('Net-LDAP-postixAccount new:0: "baseDN" is not defined');
		return undef;
	}

	my $self={error=>undef, set=>undef, baseDN=>$args{baseDN}};
	bless $self;

	#if it is defined it sets the topless setting to what ever it is
	if (defined($args{topless})) {
		$self->{topless}=$args{topless};
	}else {
		$self->{topless}=undef;
	}

	return $self;
}

=head2 create

Creates a new Net::LDAP::Entry object.

=head3 name

The name of the user.

=head3 cn

What the common name should be for a user. This defaults to the username
if it is not defined.

=head3 uid

This is the UID number of a user. If set to 'AUTO', 'Sys::User::UIDhelper'
will be used.

=head3 gid

This is GID number of a user. If set to 'AUTO', 'Sys::Group::GIDhelper'
will be used.

=head3 gecos

This is the GECOS field for a user. If it is not defined, the name is used.

=head3 loginShell

This is the login shell for the user. If it is not defined, it is set  to 
'/sbin/nologin'.

=head3 home

This is the home directory of a user. If it is not defined, it is set to
'/home/<name>'.

=head3 primary

This is the attribute that will be used for when creating the entry. 'uid',
'uidNumber', or 'cn' are the accepted value. The default is 'uid'.

=head3 description

This is the LDAP description field. If it is not defined, it is set to gecos.

=head3 minUID

This is the min UID that will be used if 'uid' is set to 'AUTO'. The default is
'1001'.

=head3 maxUID

This is the max UID that will be used if 'uid' is set to 'AUTO'. The default is
'64000'.

=head3 minGID

This is the min GID that will be used if 'gid' is set to 'AUTO'. The default is
'1001'.

=head3 maxGID

This is the max GID that will be used if 'gid' is set to 'AUTO'. The default is
'64000'.

=cut

sub create {
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#error if name is not defined
	if (!defined($args{name})) {
		warn('Net-LDAP-posixAccount create:1: name not defined');
		$self->{error}=1;
		$self->{errorString}='name not defined';
 		return undef;
	}

	#set CN to name if it is not defined
	if (!defined($args{cn})) {
		$args{cn}=$args{name};
	}

	#error if uid is not defined
	if (!defined($args{uid})) {
		warn('Net-LDAP-posixAccount create:2: uid not defined');
		$self->{error}=2;
		$self->{errorString}='uid not defined';
		return undef;
	}

	#handles choosing the UID if it is set to AUTO
	if ($args{uid} eq 'AUTO') {
		#sets the minUID if it is not defined
		if (!defined($args{minUID} eq '1001')) {
			$args{uid}='1001';
		}

		#sets the maxUID if it is not defined
		if (!defined($args{minUID})) {
			$args{uid}='64000';
		}

		#creates it
		my $uidhelper=Sys::User::UIDhelper->new({
												 min=>$args{minUID},
												 max=>$args{maxUID}
												 });
		#gets the first free one
		$args{uid}=$uidhelper->firstfree();
	}

	#error if gid is not defined
	if (!defined($args{gid})) {
		warn('Net-LDAP-posixAccount create:3: gid not defined');
		$self->{error}=3;
		$self->{errorString}='gid not defined';
		return undef;
	}

	#handles choosing the GID if it is set to AUTO
	if ($args{gid} eq 'AUTO') {
		#sets the minUID if it is not defined
		if (!defined($args{minGID} eq '1001')) {
			$args{uid}='1001';
		}

		#sets the maxUID if it is not defined
		if (!defined($args{minGID})) {
			$args{uid}='64000';
		}

		#creates it
		my $gidhelper=Sys::Group::GIDhelper->new({
												 min=>$args{minGID},
												 max=>$args{maxGID}
												 });
		#gets the first free one
		$args{gid}=$gidhelper->firstfree();
	}

	#set gecos to name if it is not defined
	if (!defined($args{gecos})) {
		if (defined($args{description})) {
			$args{gecos}=$args{description};
		}else{
			$args{gecos}=$args{name};
		}
	}

	#sets the description field
	if (!defined($args{description})) {
		if (defined($args{gecos})) {
			$args{description}=$args{gecos};
		}
	}

	#sets the loginShell to '/sbin/nologin' if it is not defined
	if (!defined($args{loginShell})) {
		$args{loginShell}='/sbin/nologin';
	}	

	#sets the home if it is not specified
	if (!defined($args{home})) {
		$args{loginShell}='/home/'.$args{name};
	}	

	#set primary if it is not defined
	if (!defined($args{primary})) {
		$args{primary}='uid';
	}

	#
	my @primary=('uid', 'cn', 'uidNumber');
	my $dn=undef;
	my $primaryInt=0;
	while (defined($primary[$primaryInt])) {
		#when a match is found, use it to begin forming the the DN
		if ($args{primary} eq $primary[$primaryInt]) {
			$dn=$args{primary}.'=';
		}
		$primaryInt++;
	}

	#error if none is matched
	if (!defined($dn)) {
		warn('Net-LDAP-posixAccount create:4: primary is a invalid value');
		$self->{error}=4;
		$self->{errorString}='primary is a invalid value';
		return undef;
	}

	#forms the DN if it is using the UID
	if ($args{primary} eq 'uid') {
		$dn=$dn.$args{name};
	}

	#forms the DN if it is using the uidNumber
	if ($args{primary} eq 'uidNumber') {
		$dn=$dn.$args{uid};
	}

	#forms the DN if it is using the CN
	if ($args{primary} eq 'cn') {
		$dn=$dn.$args{cn};
	}

	#full forms the DN
	$dn=$dn.','.$self->{baseDN};

	#creates a new object
	my $entry = Net::LDAP::Entry->new;

	#sets the dn
	$entry->dn($dn);

	#adds top if it is not topless
	if (!$args{topless}) {
		$entry->add(objectClass=>['top']);
	}

	#adds the various attributes
	$entry->add(objectClass=>['account', 'posixAccount'],
				uidNumber=>[$args{uid}], gidNumber=>[$args{gid}],
				uid=>[$args{name}], homeDirectory=>[$args{home}],
				gecos=>[$args{gecos}], loginShell=>[$args{loginShell}],
				cn=>[$args{cn}], description=>[$args{description}]);

	return $entry;
}

=head2 errorBlank

A internal function user for clearing an error.

=cut

#blanks the error flags
sub errorBlank{
	my $self=$_[0];

	#error handling
	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
};

=head1 Error Codes

=head2 0

Missing baseDN.

=head2 1

'name' not defined.

=head2 2

'uid' not defined.

=head2 3

'gid' not defined.

=head2 4

The primary value is a invalid value.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ldap-posixaccount at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-posixAccount>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::posixAccount


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-posixAccount>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-posixAccount>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-posixAccount>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-posixAccount>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::LDAP::posixAccount
