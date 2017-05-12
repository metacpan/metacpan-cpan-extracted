package Net::LDAP::posixGroup;

use warnings;
use strict;
use Net::LDAP::Entry;

=head1 NAME

Net::LDAP::posixGroup - Creates new Net::LDAP::Entry objects for a posixGroup entry.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

    use Net::LDAP::posixGroup;

    my $foo = Net::LDAP::posixGroup->new({baseDN=>'ou=group,dc=foo'});
    
    #creates a new entry with the minimum requirements
    my $entry = $foo->create({name=>'vvelox', gid=>'404'}, ['user1', 'user2']);


=head1 FUNCTIONS

=head2 new

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#returns undef if the baseDN is not set
	if (!defined($args{baseDN})) {
		warn('Net-LDAP-postixGroup new:0: "baseDN" is not defined');
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

Creates a new Net::LDAP::Entry object. The first value is a
hash. See the below for avialble values. The second is a array
with the group members.

=head3 name

The group name. This is required.

=head3 gid

The numeric GID of a group. This is required.

=head3 description

A optional LDAP desciption. This is optional.

=head3 primary

The accepted values are 'cn' and 'gidNumber'.

=cut

sub create{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my @members;
	if (defined($_[2])) {
		@members=@{$_[2]};
	}

	#error if name is not defined
	if (!defined($args{name})) {
		warn('Net-LDAP-posixGroup create:1: name not defined');
		$self->{error}=1;
		$self->{errorString}='name not defined';
 		return undef;
	}

	#error if name is not defined
	if (!defined($args{name})) {
		warn('Net-LDAP-posixGroup create:2: gid not defined');
		$self->{error}=2;
		$self->{errorString}='gid not defined';
 		return undef;
	}

	#sets the primary if it is not defined
	if (!defined($args{primary})) {
		$args{primary}='cn';
	}

	#verifies the primary
	my @primary=('gid', 'cn');
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
		warn('Net-LDAP-posixGroup create:3: primary is a invalid value');
		$self->{error}=3;
		$self->{errorString}='primary is a invalid value';
		return undef;
	}
	
	#forms the DN if it is using the gidNumber
	if ($args{primary} eq 'gidNumber') {
		$dn=$dn.$args{uid};
	}

	#forms the DN if it is using the CN
	if ($args{primary} eq 'cn') {
		$dn=$dn.$args{name};
	}

	#full forms the DN
	$dn=$dn.','.$self->{baseDN};

	#creates a new object
	my $entry = Net::LDAP::Entry->new;

	#sets the dn
	$entry->dn($dn);

	#adds the various attributes
	$entry->add(objectClass=>['posixGroup', 'top'],
				gidNumber=>[$args{gid}], cn=>[$args{name}]);

	#adds the description if needed
	if (defined($args{description})) {
		$entry->add(description=>[$args{description}]);
	}

	my $membersInt=0;
	while (defined($members[$membersInt])) {
		$entry->add(memberUid=>[$members[$membersInt]]);

		$membersInt++;
	}

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

No group name specified.

=head2 2

No GID specified.

=head2 3

The primary is a invalid value.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ldap-posixgroup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-posixGroup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::posixGroup


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-posixGroup>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-posixGroup>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-posixGroup>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-posixGroup>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::LDAP::posixGroup
