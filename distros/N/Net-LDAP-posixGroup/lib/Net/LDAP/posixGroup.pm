package Net::LDAP::posixGroup;

use warnings;
use strict;
use Net::LDAP::Entry;
use base 'Error::Helper';

=head1 NAME

Net::LDAP::posixGroup - Creates new Net::LDAP::Entry objects for a posixGroup entry.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use Net::LDAP::posixGroup;

    my $foo = Net::LDAP::posixGroup->new(baseDN=>'ou=group,dc=foo');

    # creates a new for the group newGroup with a GID of 404 and members of user1 and user2.
    my $entry = $foo->create(name=>'newGroup', gid=>'404', members=>['user1', 'user2']);

    print $entry->ldif;

=head1 FUNCTIONS

=head2 new

This initiates the object.

    - baseDN :: This is a required value and is the base that the entry will
            be created under.

    - topless :: This is a perl boolean value. If this is set to true, the
            objectClass top is not present.

=cut

sub new {
	my ( $blank, %args ) = @_;

	# returns undef if the baseDN is not set
	if ( !defined( $args{baseDN} ) ) {
		warn('Net-LDAP-postixGroup new:0: "baseDN" is not defined');
		return undef;
	}

	#returns undef if the baseDN is not set
	my $self = {
		perror        => undef,
		error         => undef,
		errorLine     => undef,
		errorFilename => undef,
		errorString   => "",
		errorExtra    => {
			all_errors_fatal => 1,
			flags            => {
				1 => 'noGroupName',
				2 => 'noGID',
				3 => 'invalidPrimary',
				4 => 'noBaseDN',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		baseDN  => undef,
		topless => undef,
	};
	bless $self;

	# if it is defined it sets the topless setting to what ever it is
	if ( defined( $args{topless} ) ) {
		$self->{topless} = $args{topless};
	} else {
		$self->{topless} = undef;
	}

	# check to see if the base DN looks legit
	if ( $args{baseDN} !~ /^(?:(?:[A-Za-z0-9]+=[^,]+),\s*)*(?:[A-Za-z0-9]+=[^,]+)$/ ) {
		$self->{error}       = 6;
		$self->{errorString} = 'baseDN, "' . $args{baseDN} . '", does not appear to be a valid DN';
		$self->{perror}      = 1;
		$self->warn;
		return $self;
	}

	$self->{baseDN} = $args{baseDN};

	return $self;
} ## end sub new

=head2 create

Creates a new Net::LDAP::Entry object.

The following args are required.

    - name ::  The group name.

    - gid :: The numeric GID of a group.

The following are optional.

    - description :: A optional LDAP desciption.

    - primary :: The accepted values are 'cn' and 'gidNumber'.
        - default :: cn

=cut

sub create {
	my ( $self, %args ) = @_;

	$self->errorblank;

	my @members;
	if ( defined( $args{members} ) ) {
		@members = @{ $args{members} };
	}

	# error if name is not defined
	if ( !defined( $args{name} ) ) {
		$self->{error}       = 1;
		$self->{errorString} = 'name not defined';
		$self->warn;
		return undef;
	}

	# error if name is not defined
	if ( !defined( $args{name} ) ) {
		$self->{error}       = 2;
		$self->{errorString} = 'gid not defined';
		$self->warn;
		return undef;
	}

	# sets the primary if it is not defined
	if ( !defined( $args{primary} ) ) {
		$args{primary} = 'cn';
	}

	# verifies the primary
	my @primary    = ( 'gid', 'cn' );
	my $dn         = undef;
	my $primaryInt = 0;
	while ( defined( $primary[$primaryInt] ) ) {
		#when a match is found, use it to begin forming the the DN
		if ( $args{primary} eq $primary[$primaryInt] ) {
			$dn = $args{primary} . '=';
		}
		$primaryInt++;
	}

	#error if none is matched
	if ( !defined($dn) ) {
		$self->{error}       = 3;
		$self->{errorString} = 'primary is a invalid value';
		$self->warn;
		return undef;
	}

	#forms the DN if it is using the gidNumber
	if ( $args{primary} eq 'gidNumber' ) {
		$dn = $dn . $args{uid};
	}

	#forms the DN if it is using the CN
	if ( $args{primary} eq 'cn' ) {
		$dn = $dn . $args{name};
	}

	#full forms the DN
	$dn = $dn . ',' . $self->{baseDN};

	#creates a new object
	my $entry = Net::LDAP::Entry->new;

	#sets the dn
	$entry->dn($dn);

	#adds the various attributes
	$entry->add(
		objectClass => [ 'posixGroup', 'top' ],
		gidNumber   => [ $args{gid} ],
		cn          => [ $args{name} ]
	);

	#adds the description if needed
	if ( defined( $args{description} ) ) {
		$entry->add( description => [ $args{description} ] );
	}

	my $membersInt = 0;
	while ( defined( $members[$membersInt] ) ) {
		$entry->add( memberUid => [ $members[$membersInt] ] );

		$membersInt++;
	}

	return $entry;
} ## end sub create

=head1 Error Codes

All error codes are considered fatal, allowing for easy cheacking via eval.

=head2 1, noGroupName

No group name specified.

=head2 2, noGID

No GID specified.

=head2 3, invalidPrimary

The primary is a invalid value.

=head2 4, noBaseDN

Missing baseDN.

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

=item * Search CPAN

L<http://metacpan.org/dist/Net-LDAP-posixGroup>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2023 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Net::LDAP::posixGroup
