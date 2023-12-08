package Net::LDAP::posixAccount;

use warnings;
use strict;
use Net::LDAP::Entry;
use Sys::User::UIDhelper;
use Sys::Group::GIDhelper;
use base 'Error::Helper';

=head1 NAME

Net::LDAP::posixAccount - Creates new Net::LDAP::Entry objects for a posixAccount entry.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use Net::LDAP::posixAccount;

    # Initiates the module with a base DN of 'ou=users,dc=foo'.
    my $foo = Net::LDAP::posixAccount->new(baseDN=>'ou=user,dc=foo');

    # create the user vvelox with a gid of 404 and a uid of 404
    my $entry = $foo->create(name=>'vvelox', gid=>'404', uid=>'404');

    # add it using $ldap, a previously created Net::LDAP object
    $entry->update($ldap);

=head1 METHODS

=head2 new

This initiates the module. It accepts one arguement, a hash. Please See below
for accepted values.

    - baseDN :: This is a required value and is the base that the entry will
            be created under.

    - topless :: This is a perl boolean value. If this is set to true, the
            objectClass top is not present.

=cut

sub new {
	my ( $blank, %args ) = @_;

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
				1 => 'missing_name',
				2 => 'missing_uid',
				3 => 'missing_gid',
				4 => 'invalid_value',
				5 => 'missing_baseDN',
				6 => 'invalid_baseDN',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		baseDN  => undef,
		topless => undef,
	};
	bless $self;

	#if it is defined it sets the topless setting to what ever it is
	if ( defined( $args{topless} ) ) {
		$self->{topless} = $args{topless};
	}

	if ( !defined( $args{baseDN} ) ) {
		$self->{error}       = 5;
		$self->{errorString} = 'baseDN is not defined';
		$self->{perror}      = 1;
		$self->warn;
		return $self;
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

    - name :: The name of the user.

    - cn :: What the common name should be for a user. This defaults to the username if it is not defined.

    - uid ::This is the UID number of a user. If set to 'AUTO', Sys::User::UIDhelper will be used.

    - gid :: This is GID number of a user. If set to 'AUTO', Sys::Group::GIDhelper will be used.

    - gecos :: This is the GECOS field for a user. If it is not defined, the name is used.

    - loginShell This is the login shell for the user.
        - default :: /sbin/nologin

    - home ::This is the home directory of a user.
        - default :: /home/$name

    - primary :: This is the attribute that will be used for when creating the entry.
            'uid', 'uidNumber', or 'cn' are the accepted value. The default is 'uid'.

    - description :: This is the LDAP description field. If it is not defined, it is set to gecos.

    - minUID :: This is the min UID that will be used if 'uid' is set to 'AUTO'.
        - default :: 1001

    - maxUID This is the max UID that will be used if 'uid' is set to 'AUTO'.
        - default :: 64000

    - minGID :: This is the min GID that will be used if 'gid' is set to 'AUTO'.
        - default :: 1001

    - maxGID ::  This is the max GID that will be used if 'gid' is set to 'AUTO'.
        - default :: 64000

=cut

sub create {
	my ( $self, %args ) = @_;

	$self->errorblank;

	#error if name is not defined
	if ( !defined( $args{name} ) ) {
		$self->{error}       = 1;
		$self->{errorString} = 'name not defined';
		$self->warn;
	}

	#set CN to name if it is not defined
	if ( !defined( $args{cn} ) ) {
		$args{cn} = $args{name};
	}

	#error if uid is not defined
	if ( !defined( $args{uid} ) ) {
		$self->{error}       = 2;
		$self->{errorString} = 'uid not defined';
		$self->warn;
	}

	#handles choosing the UID if it is set to AUTO
	if ( $args{uid} eq 'AUTO' ) {
		#sets the minUID if it is not defined
		if ( !defined( $args{minUID} eq '1001' ) ) {
			$args{uid} = '1001';
		}

		#sets the maxUID if it is not defined
		if ( !defined( $args{minUID} ) ) {
			$args{uid} = '64000';
		}

		#creates it
		my $uidhelper = Sys::User::UIDhelper->new(
			min => $args{minUID},
			max => $args{maxUID}
		);
		#gets the first free one
		$args{uid} = $uidhelper->firstfree();
	} ## end if ( $args{uid} eq 'AUTO' )

	#error if gid is not defined
	if ( !defined( $args{gid} ) ) {
		$self->{error}       = 3;
		$self->{errorString} = 'gid not defined';
		$self->warn;
	}

	#handles choosing the GID if it is set to AUTO
	if ( $args{gid} eq 'AUTO' ) {
		#sets the minUID if it is not defined
		if ( !defined( $args{minGID} eq '1001' ) ) {
			$args{uid} = '1001';
		}

		#sets the maxUID if it is not defined
		if ( !defined( $args{minGID} ) ) {
			$args{uid} = '64000';
		}

		#creates it
		my $gidhelper = Sys::Group::GIDhelper->new(
			min => $args{minGID},
			max => $args{maxGID}
		);
		#gets the first free one
		$args{gid} = $gidhelper->firstfree();
	} ## end if ( $args{gid} eq 'AUTO' )

	#set gecos to name if it is not defined
	if ( !defined( $args{gecos} ) ) {
		if ( defined( $args{description} ) ) {
			$args{gecos} = $args{description};
		} else {
			$args{gecos} = $args{name};
		}
	}

	#sets the description field
	if ( !defined( $args{description} ) ) {
		if ( defined( $args{gecos} ) ) {
			$args{description} = $args{gecos};
		}
	}

	#sets the loginShell to '/sbin/nologin' if it is not defined
	if ( !defined( $args{loginShell} ) ) {
		$args{loginShell} = '/sbin/nologin';
	}

	#sets the home if it is not specified
	if ( !defined( $args{home} ) ) {
		$args{loginShell} = '/home/' . $args{name};
	}

	#set primary if it is not defined
	if ( !defined( $args{primary} ) ) {
		$args{primary} = 'uid';
	}

	#
	my @primary    = ( 'uid', 'cn', 'uidNumber' );
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
		$self->{error}       = 4;
		$self->{errorString} = 'primary is a invalid value';
		$self->warn;
	}

	#forms the DN if it is using the UID
	if ( $args{primary} eq 'uid' ) {
		$dn = $dn . $args{name};
	}

	#forms the DN if it is using the uidNumber
	if ( $args{primary} eq 'uidNumber' ) {
		$dn = $dn . $args{uid};
	}

	#forms the DN if it is using the CN
	if ( $args{primary} eq 'cn' ) {
		$dn = $dn . $args{cn};
	}

	#full forms the DN
	$dn = $dn . ',' . $self->{baseDN};

	#creates a new object
	my $entry = Net::LDAP::Entry->new;

	#sets the dn
	$entry->dn($dn);

	#adds top if it is not topless
	if ( !$args{topless} ) {
		$entry->add( objectClass => ['top'] );
	}

	#adds the various attributes
	$entry->add(
		objectClass   => [ 'account', 'posixAccount' ],
		uidNumber     => [ $args{uid} ],
		gidNumber     => [ $args{gid} ],
		uid           => [ $args{name} ],
		homeDirectory => [ $args{home} ],
		gecos         => [ $args{gecos} ],
		loginShell    => [ $args{loginShell} ],
		cn            => [ $args{cn} ],
		description   => [ $args{description} ]
	);

	return $entry;
} ## end sub create

=head2 errorBlank

A internal function user for clearing an error.

=cut

#blanks the error flags
sub errorBlank {
	my $self = $_[0];

	#error handling
	$self->{error}       = undef;
	$self->{errorString} = "";

	return 1;
}

=head1 Error Codes/Flags

L<Error::Helper> is used and all errors are considered fatal.

=head2 1/missing_name

'name' not defined.

=head2 2/missing_uid

'uid' not defined.

=head2 3/missing_gid

'gid' not defined.

=head2 4/invalid_value

The primary value is a invalid value.

=head2 5/missing_baseDN

Missing baseDN.

=head2 6/invalid_baseDN

The specified base DN does does not appear to be a DN.

Checked via the regex below.

    ^(?:(?:[A-Za-z0-9]+=[^,]+),\s*)*(?:[A-Za-z0-9]+=[^,]+)$

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

1;    # End of Net::LDAP::posixAccount
