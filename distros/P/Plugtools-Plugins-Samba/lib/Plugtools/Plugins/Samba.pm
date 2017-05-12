package Plugtools::Plugins::Samba;

use warnings;
use strict;
use Samba::SIDhelper;
use Crypt::SmbHash qw(lmhash nthash);

=head1 NAME

Plugtools::Plugins::Samba - Provides various methods used by the plugins in this.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';


=head1 SYNOPSIS

This module provides a collection of methods used by the Samba plugins for
Plugtools.

    use Plugtools::Plugins::Samba;
    use Plugtools;

    my $pt=Plugtools->new;

    my $ldap=$pt->connect;

    my $pts = Plugtools::Plugins::Samba->new({
                                              pt=>$pt,
                                              ldap=>$ldap
                                             });
    ...

=head1 METHODS

=head2 new

This initiates it.

=head3 args hash

=head4 pt

This is a Plugtools object that has been successfully initiated.

=head4 ldap

This is the LDAP connection to use.

    my $pts = Plugtools::Plugins::Samba->new({
                                              pt=>$pt,
                                              ldap=>$ldap
                                             });
    if($pts->{error}){
        print "Error!\n";
    }

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self = {error=>undef, errorString=>""};
	bless $self;

	#make sure we have a Plugtools object and if we do, get it
	if (!defined($args{pt})) {
		$self->{error}=1;
		$self->{errorString}='$args{pt} is undefined';
		warn('Plugtools new:1: '.$self->{errorString});
		return $self;
	}
	$self->{pt}=$args{pt};

	#make sure a SID is specified in the config file
	if (!defined( $self->{pt}->{ini}->{samba}->{sid} )) {
		$self->{error}=4;
		$self->{errorString}='No value for "sid" defined in the section "samba" of the config file.';
		warn('Plugtools-Plugins-Samba new:4: '.$self->{errorString});
		return $self;
	}

	$self->{sidhelper}=Samba::SIDhelper->new( { sid=>$self->{pt}->{ini}->{samba}->{sid} } );
	if ($self->{sidhelper}->{error}) {
		$self->{error}=5;
		$self->{errorString}='Samba::SIDhelper errored. $self->{sidhelper}->{error}="'.$self->{sidhelper}->{error}
		                     .'" $self->{sidhelper}->{errorString}="'.$self->{sidhelper}->{error}.'"';
		warn('Plugtools-Plugins-Samba new:5: ',$self->{errorString});
		return $self;
	}

	#make sure we got a LDAP connection
	if (!defined($args{ldap})) {
		$self->{error}=2;
		$self->{errorString}='$args{pt} is undefined';
		warn('Plugtools new:1: '.$self->{errorString});
		return $self;
	}
	$self->{ldap}=$args{ldap};

	return $self;
}

=head2 isSambaAccountEntry

This check if all the basic stuff is present for it to
be useful in regards to Samba. This checks to make sure
the objectclass 'sambaSamAccount' and the attributes 'sambaSID'
and 'sambaPrimaryGroupSID' are present.

=head3 args hash

=head4 entry

This is the LDAP entry that will be used.

    my $returned=$pts->isSambaAccountEntry({entry=>$entry});
    if($pts->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "It is!\n";
        }
    }

=cut

sub isSambaAccountEntry{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	$self->errorblank;

	#make sure we have a LDAP entry
	if (!defined($args{entry})) {
		$self->{error}=3;
		$self->{errorString}='No LDAP entry defined';
		warn('Plugtools-Plugins-Samba isSambaAccountEntry:3: '.$self->{errorString});
		return undef;
	}

	#check if any of the object classes are the correct type
	my @objectClasses=$args{entry}->get_value('objectClass');
	my $int=0;
	my $found=0;
	while (defined($objectClasses[$int])) {
		if ($objectClasses[$int] eq 'sambaSamAccount') {
			$found=1;
		}

		$int++;
	}
	if (!$found) {
		return undef;
	}

	#make sure we have a SID
	my $sid=$args{entry}->get_value('sambaSID');
	if (!defined($sid)) {
		return undef;
	}

	#make sure we have a primary group SID
	my $pgsid=$args{entry}->get_value('sambaPrimaryGroupSID');
	if (!defined($pgsid)) {
		return undef;
	}

	return 1;
}

=head2 makeSambaAccountEntry

If a entry is not already a Samba account, make it one.

If it already is, it will error.

This will not update the entry that is passed to it. That will
need to be done upon this returning with out any errors being
set.

=head3 args hash

=head4 entry

This is the Net::LDAP::Entry object to work on.

=head4 sid

This is the SID to use for the entry.

=head4 pgsid

This is the primary group SID to use.

    $pts->makeSambaAccountEntry({ entry=>$entry });
    if($pts->{error}){
        print "Error!\n";
    }

    $pts->makeSambaAccountEntry({
                                 entry=>$entry,
                                 sid=>$sid,
                                 pgsid=>$pgsid,
                                });
    if($pts->{error}){
        print "Error!\n";
    }

=cut

sub makeSambaAccountEntry{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#make sure we have a LDAP entry
	if (!defined($args{entry})) {
		$self->{error}=3;
		$self->{errorString}='No LDAP entry defined';
		warn('Plugtools-Plugins-Samba makeSambaAccountEntry:3: '.$self->{errorString});
		return undef;
	}

	#check if it is already a samba account or not
	my $returned=$self->isSambaAccountEntry({ entry=>$args{entry} });
	if ($self->{error}) {
		warn('Plugtools-Plugins-Samba makeSambaAccountEntry: isSambaAccountEntry failed');
		return undef;
	}
	if ($returned) {
		$self->{error}=7;
		$self->{errorString}='The entry, "'.$args{entry}->dn.'", is already a samba account';
		warn('Plugtools-Plugins-Samba makeSambaAccountEntry:7: '.$self->{errorString});
		return undef;
	}
	
	#make sure we have a SID
	if (!defined($args{sid})) {
		my $uid=$args{entry}->get_value('uidNumber');
		if (!defined($uid)) {
			$self->{error}=6;
			$self->{errorString}='No "uidNumber" attribute present for "'.$args{entry}->dn.'"';
			warn('Plugtools-Plugins-Samba makeSambaAccountEntry:6: '.$self->{errorString});
			return undef;
		}

		$args{sid}=$self->{sidhelper}->uid2sid($uid);
		if ($self->{sidhelper}->{error}) {
			$self->{error}=5;
			$self->{errorString}='Samba::SIDhelper errored. $self->{sidhelper}->{error}="'.$self->{sidhelper}->{error}
			                     .'" $self->{sidhelper}->{errorString}="'.$self->{sidhelper}->{error}.'"';
			warn('Plugtools-Plugins-Samba makeSanbaAccountEntry:5: ',$self->{errorString});
			return undef;
		}
	}

	#make sure we have a pgsid
	if (!defined($args{pgsid})) {
		my $gid=$args{entry}->get_value('gidNumber');
		if (!defined($gid)) {
			$self->{error}=8;
			$self->{errorString}='No "gidNumber" attribute present for "'.$args{entry}->dn.'"';
			warn('Plugtools-Plugins-Samba makeSambaAccountEntry:8: '.$self->{errorString});
			return undef;
		}

		$args{pgsid}=$self->{sidhelper}->gid2sid($gid);
		if ($self->{sidhelper}->{error}) {
			$self->{error}=5;
			$self->{errorString}='Samba::SIDhelper errored. $self->{sidhelper}->{error}="'.$self->{sidhelper}->{error}
			                     .'" $self->{sidhelper}->{errorString}="'.$self->{sidhelper}->{error}.'"';
			warn('Plugtools-Plugins-Samba makeSanbaAccountEntry:5: ',$self->{errorString});
			return undef;
		}
	}
	
	#isSambaAccountEntry just checks if it is properly setup... if one of the following is missing,
	#then it should be removed and then re-added
	my $sid=$args{entry}->get_value('sambaSID');
	if (defined($sid)) {
		$args{entry}->delete('sambaSID');
	}
	my $pgsid=$args{entry}->get_value('sambaPrimaryGroupSID');
	if (defined($pgsid)) {
		$args{entry}->delete('sambaPrimaryGroupSID');
	}
	my @ocA=$args{entry}->get_value('objectClass');
	my $int=0;
	while (defined($ocA[$int])) {
		if ($ocA[$int] eq 'sambaSamAccount') {
			$args{entry}->delete('objectClass'=>'sambaSamAccount');
		}

		$int++;
	}

	$args{entry}->add('objectClass'=>'sambaSamAccount');
	$args{entry}->add('sambaSID'=>$args{sid});
	$args{entry}->add('sambaPrimaryGroupSID'=>$args{pgsid});

	return 1;
}

=head2 removeSambaAcctEntry

Remove the samba stuff from a user.

=head3 entry

This is a Net::LDAP::Entry to remove attributes
related to sambaSamAccount from.

=cut

sub removeSambaAcctEntry{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#make sure we have a LDAP entry
	if (!defined($args{entry})) {
		$self->{error}=3;
		$self->{errorString}='No LDAP entry defined';
		warn('Plugtools-Plugins-Samba makeSambaAccountEntry:3: '.$self->{errorString});
		return undef;
	}

	my @OCs=$args{entry}->get_value('objectClass');
	my $int=0;
	my $matched=0;
	while (defined($OCs[$int])) {
		if ($OCs[$int] eq 'sambaSamAccount') {
			$matched=1;
		}

		$int++;
	}

	#nothing to do
	if (!$matched) {
		return 1;
	}

	$args{entry}->delete('objectClass'=>'sambaSamAccount');

	my @attributes=(
					'sambaLMPassword',
					'sambaNTPassword',
					'sambaPwdLastSet',
					'sambaLogonTime',
					'sambaLogoffTime',
					'sambaKickoffTime',
					'sambaPwdCanChange',
					'sambaPwdMustChange',
					'sambaAcctFlags',
					'sambaHomePath',
					'sambaHomeDrive',
					'sambaLogonScript',
					'sambaProfilePath',
					'sambaUserWorkstations',
					'sambaPrimaryGroupSID',
					'sambaDomainName',
					'sambaMungedDial',
					'sambaBadPasswordCount',
					'sambaBadPasswordTime',
					'sambaPasswordHistory',
					'sambaLogonHours',
					);

	#tests for any possible attributes
	$int=0;
	while ($attributes[$int]) {
		my $test=$args{entry}=get_value($attributes[$int]);

		#if it is is present, remove it
		if (defined($test)) {
			$args{entry}->delete($attributes[$int]);
		}

		$int++;
	}

	return 1;
}

=head2 setPassEntry

This sets the password for a Samba account.

=head3 args hash

=head4 entry

This is the Net::LDAP::Entry object to work on.

=head4 pass

This is the password to set.

    $pts->setPassEntry({
                       entry=>$entry,
                       pass=>'somepass',
                       });
    if($pts->{error}){
        print "Error!\n";
    }

=cut

sub setPassEntry{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	$self->errorblank;

	#make sure we have a LDAP entry
	if (!defined($args{entry})) {
		$self->{error}=3;
		$self->{errorString}='No LDAP entry defined';
		warn('Plugtools-Plugins-Samba setPassEntry:3: '.$self->{errorString});
		return undef;
	}

	#check if it is already a samba account or not
	my $returned=$self->isSambaAccountEntry({ entry=>$args{entry} });
	if ($self->{error}) {
		warn('Plugtools-Plugins-Samba makeSambaAccountEntry: isSambaAccountEntry failed');
		return undef;
	}
	if (!$returned) {
		$self->{error}=10;
		$self->{errorString}='The entry, "'.$args{entry}->dn.'", is not a samba account';
		warn('Plugtools-Plugins-Samba setPassEntry:10: '.$self->{errorString});
		return undef;
	}

	#make sure we have a password
	if (!defined($args{pass})) {
		$self->{error}=9;
		$self->{errorString}='No password specified';
		warn('Plugtools-Plugins-Samba setPAssEntry:9: '.$self->{errorString});
		return undef;
	}

	my $ntp=$args{entry}->get_value('sambaNTPassword');
	if ($ntp) {
		$args{entry}->delete('sambaNTPassword');
	}

	my $lmp=$args{entry}->get_value('sambaLMPassword');
	if ($lmp) {
		$args{entry}->delete('sambaLMPassword');
	}

	$lmp=$args{entry}->get_value('sambaPwdLastSet');
	if ($lmp) {
		$args{entry}->delete('sambaPwdLastSet');
	}

	$args{entry}->add('sambaNTPassword'=>nthash($args{pass}));
	$args{entry}->add('sambaLMPassword'=>lmhash($args{pass}));
	$args{entry}->add('sambaPwdLastSet'=>time());

	return 1;
}

=head2 sidUpdateEntry

=head3 args hash

=head4 entry

This is the Net::LDAP::Entry object to work on.

=cut

sub sidUpdateEntry{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	$self->errorblank;

	#make sure we have a LDAP entry
	if (!defined($args{entry})) {
		$self->{error}=3;
		$self->{errorString}='No LDAP entry defined';
		warn('Plugtools-Plugins-Samba sidUpdateEntry:3: '.$self->{errorString});
		return undef;
	}

	#check if it is already a samba account or not
	my $returned=$self->isSambaAccountEntry({ entry=>$args{entry} });
	if ($self->{error}) {
		warn('Plugtools-Plugins-Samba sidUpdateEntry: isSambaAccountEntry failed');
		return undef;
	}
	if (!$returned) {
		$self->{error}=10;
		$self->{errorString}='The entry, "'.$args{entry}->dn.'", is not a samba account';
		warn('Plugtools-Plugins-Samba sidUpdateEntry:10: '.$self->{errorString});
		return undef;
	}

	#make sure we have a uid
	my $uid=$args{entry}->get_value('uidNumber');
	if (!defined($uid)) {
		$self->{error}=11;
		$self->{errorString}='"'.$args{entry}->dn.'" lacks a uidNumber attribute';
		warn('Plugtools-Plugins-Samba sidUpdateEntry:11: '.$self->{errorString});
		return undef;
	}

	#make sure we have a gid
	my $gid=$args{entry}->get_value('gidNumber');
	if (!defined($gid)) {
		$self->{error}=12;
		$self->{errorString}='"'.$args{entry}->dn.'" lacks a gidNumber attribute';
		warn('Plugtools-Plugins-Samba sidUpdateEntry:12: '.$self->{errorString});
		return undef;
	}

	#remove the old values
	$args{entry}->delete('sambaSID');
	$args{entry}->delete('sambaPrimaryGroupSID');

	#convert the uid
	my $sid=$self->{sidhelper}->uid2sid($uid);
	if ($self->{sidhelper}->{error}) {
		$self->{error}=5;
		$self->{errorString}='Samba::SIDhelper errored. $self->{sidhelper}->{error}="'.$self->{sidhelper}->{error}
		                     .'" $self->{sidhelper}->{errorString}="'.$self->{sidhelper}->{error}.'"';
		warn('Plugtools-Plugins-Samba sidUpdateEntry:5: ',$self->{errorString});
		return undef;
	}

	#convert the gid
	my $pgsid=$self->{sidhelper}->gid2sid($gid);
	if ($self->{sidhelper}->{error}) {
		$self->{error}=5;
		$self->{errorString}='Samba::SIDhelper errored. $self->{sidhelper}->{error}="'.$self->{sidhelper}->{error}
		                     .'" $self->{sidhelper}->{errorString}="'.$self->{sidhelper}->{error}.'"';
		warn('Plugtools-Plugins-Samba sidUpdateEntry:5: ',$self->{errorString});
		return undef;
	}

	#add the new values
	$args{entry}->add('sambaSID'=>$sid);
	$args{entry}->add('sambaPrimaryGroupSID'=>$pgsid);

	return 1;
}

=head2 errorblank

This is a internal function and should not be called.

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
};

=head1 ERROR CODES

=head2 1

No Plugtools object given.

=head2 2

No LDAP connection specified.

=head2 3

No entry given.

=head2 4

No value for 'sid' defined in the section 'samba' of the config file.

=head2 5

Samba::SIDhelper errored.

=head2 6

The LDAP entry lacks a uidNumber attribute.

=head2 7

Already a samba a account.

=head2 8

The LDAP entry lacks a gidNumber attribute.

=head2 9

No password specified.

=head2 10

The LDAP entry is not a samba account.

=head2 11

The entry lacks a uidNumber attribute.

=head2 12

The entry lacks a uidNumber attribute.

=head1 Plugtools CONFIG

Only one additional setting is needed. That is 'sid' setup in the secion 'samba'.

The SID can be gotten by running 'net getlocalsid'.

    pluginUserSetPass=Plugtools::Plugins::Samba::setPass
    pluginUserGIDchange=Plugtools::Plugins::Samba::SIDupdate
    pluginUserUIDchange=Plugtools::Plugins::Samba::SIDupdate
    pluginAddUser=Plugtools::Plugins::Samba::makeSambaAccount
    [samba]
    sid=S-1-5-21-1234-5678-91011

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plugtools-plugins-samba at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plugtools-Plugins-Samba>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plugtools::Plugins::Samba


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plugtools-Plugins-Samba>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plugtools-Plugins-Samba>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plugtools-Plugins-Samba>

=item * Search CPAN

L<http://search.cpan.org/dist/Plugtools-Plugins-Samba/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Plugtools::Plugins::Samba
