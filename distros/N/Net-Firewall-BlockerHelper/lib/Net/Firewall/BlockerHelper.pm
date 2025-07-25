package Net::Firewall::BlockerHelper;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper - Helps with managing firewalls for banning IPs.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    # create a instance named ssh with a ipfw backend for port 22 tcp
    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend => 'ipfw',
                ports => ['22'],
                protocols => ['tcp'],
                name => 'ssh',
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

    # start the backend
    $fw_helper->init_backend;

    # ban some IPs
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban(ban => '5.6.7.8');

    # unban a IP
    $fw_helper->unban(ban => '1.2.3.4');

    # get a list of banned IPs
    my @banned = $fw_helper->list;
    foreach my $ip (@banned) {
        print 'Banned IP: '.$ip."\n";
    }

    # teardown the backend, re-init, and re-ban everything
    $fw_helper->re_init;

    # teardown the backend
    $fw_helper->teardown;

=head1 METHODS

=head2 new

Initiates the the object.

    - backend :: The backend to use. This must be specified.
        - Default :: undef

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are positive ints or a valid
            service name via getservbyname.
        - Default :: []

    - protocols :: A array of protocols to block. By default will block all. This
            is checked against /etc/protocols via the function getprotobyname.
        - Default :: []

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance.
        - default :: undef

All errors are considered fatal, meaning if new fails it will die.

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend => 'ipfw',
                ports => ['22'],
                protocols => ['tcp'],
                name => 'ssh',
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		perror        => undef,
		error         => undef,
		errorLine     => undef,
		errorFilename => undef,
		errorString   => "",
		errorExtra    => {
			all_errors_fatal => 1,
			flags            => {
				1  => 'noBackendSpecified',
				2  => 'invalidPortSpecified',
				3  => 'portsNotArray',
				4  => 'protocolsNotArray',
				5  => 'invalidPortSpecified',
				6  => 'invalidPrefixSpecified',
				7  => 'invalidName',
				8  => 'optionsNotHash',
				9  => 'noBanItem',
				10 => 'banItemNotIP',
				11 => 'invalidBackend',
				12 => 'backendInitError',
				13 => 'banFailed',
				14 => 'unbanFailed',
				15 => 'listFailed',
				16 => 'reInitFailed',
				17 => 'teardownFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		backend     => undef,
		options     => {},
		ports       => [],
		protocols   => [],
		testing     => undef,
		test_data   => undef,
		prefix      => 'kur',
		name        => undef,
		backend_obj => undef,
	};
	bless $self;

	if ( !defined $opts{backend} ) {
		$self->{perror}      = 1;
		$self->{error}       = 1;
		$self->{errorString} = 'backend is undef';
		$self->warn;
	}
	$self->{backend} = $opts{backend};

	if ( $self->{backend} !~ /^[a-zA-Z0-9\_]+$/ ) {
		$self->{perror} = 11;
		$self->{error}  = 1;
		$self->{errorString}
			= '"'
			. $self->{backend}
			. '" does not appear to be valid backend, the regexp /^[a-zA-Z0-9\_]+$/ does not match';
		$self->warn;
	}

	if ( defined( $opts{ports} ) && ref( $opts{ports} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 3;
		$self->{errorString} = 'ports is defined and type is not array but "' . ref( $opts{ports} ) . '"';
		$self->warn;
	} elsif ( defined( $opts{ports} ) ) {
		my %ports;
		foreach my $item ( @{ $opts{ports} } ) {
			if ( $item =~ /^[0-9]+$/ && $item >= 1 ) {
				#push( @{ $self->{ports} }, $item );
				$ports{$item} = 1;
			} elsif ( $item =~ /^[0-9]+$/ && $item < 1 ) {
				$self->{perror} = 1;
				$self->{error}  = 2;
				$self->{errorString}
					= $item . ' is not a valid value for a port as it must be a int greater or equal to 1';
				$self->warn;
			} else {
				# just using tcp here as protocol must be specified
				my ( $name, $aliases, $port, $proto ) = getservbyname( $item, 'tcp' );
				if ( !defined($port) ) {
					$self->{perror} = 1;
					$self->{error}  = 2;
					$self->{errorString}
						= $item . ' could not be resolved to a port name via getservbyname("' . $item . '", "tcp")';
					$self->warn;
				}
				$ports{$port} = 1;
				#push( @{ $self->{ports} }, $port );
			} ## end else [ if ( $item =~ /^[0-9]+$/ && $item >= 1 ) ]
		} ## end foreach my $item ( @{ $opts{ports} } )
		my @port_keys = keys(%ports);
		@port_keys = sort { $a <=> $b } @port_keys;
		push( @{ $self->{ports} }, @port_keys );
		## end foreach my $item ( @{ $opts{ports} } )
	} ## end elsif ( defined( $opts{ports} ) )

	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 4;
		$self->{errorString} = 'protocols is defined and type is not array but "' . ref( $opts{protocols} ) . '"';
		$self->warn;
	} elsif ( defined( $opts{protocols} ) ) {
		my %protocols;
		foreach my $item ( @{ $opts{protocols} } ) {
			my ( $name, $aliases, $proto ) = getprotobyname($item);
			# if this is undef, it means it is not a known protocol
			if ( !defined($proto) ) {
				$self->{perror} = 1;
				$self->{error}  = 5;
				$self->{errorString}
					= $item . ' could not be resolved to a port name via getservbyname("' . $item . '", "tcp")';
				$self->warn;
			}
			$protocols{$item} = 1;
		} ## end foreach my $item ( @{ $opts{protocols} } )
		my @protocols_keys = keys(%protocols);
		@protocols_keys = sort { $a cmp $b } @protocols_keys;
		push( @{ $self->{protocols} }, @protocols_keys );
	} ## end elsif ( defined( $opts{protocols} ) )

	# make sure prefix is sane if defiend
	if ( defined( $opts{prefix} ) && $opts{prefix} !~ /^[a-zA-Z0-9]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 6;
		$self->{errorString}
			= '"' . $opts{prefix} . '" is not a valid prefix as it does not match the regex /^[a-zA-Z0-9]+$/';
		$self->warn;
	} elsif ( defined( $opts{prefix} ) ) {
		$self->{prefix} = $opts{prefix};
	}

	# make sure we have a name and that it is valid
	if ( !defined( $opts{name} ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 6;
		$self->{errorString} = 'name is undef';
		$self->warn;
	} elsif ( $opts{name} !~ /^[a-zA-Z0-9\-]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 6;
		$self->{errorString} = 'name set to "' . $opts{name} . '" which does not match the regexp  /^[a-zA-Z0-9\-]+$/';
		$self->warn;
	}
	$self->{name} = $opts{name};

	# used internally for testing
	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}

	if ( defined( $opts{options} ) ) {
		if ( ref( $opts{options} ) ne 'HASH' ) {
			$self->{perror}      = 1;
			$self->{error}       = 8;
			$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
			$self->warn;
		}
		$self->{options} = $opts{options};
	}

	return $self;
} ## end sub new

=head2 init_backend

Initiates the backend.

No arguments are taken.

    $fw_helper->init_backend;

=cut

sub init_backend {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data}=undef;

	my $backend = 'Net::Firewall::BlockerHelper::backends::' . $self->{backend};
	my $backend_obj;
	my $init_string
		= 'use '
		. $backend
		. '; $backend_obj='
		. $backend
		. '->new('
		. 'options=>$self->{options}, '
		. 'ports=>$self->{ports}, '
		. 'protocols=>$self->{protocols}, '
		. 'testing=>$self->{testing}, '
		. 'prefix=>$self->{prefix}, '
		. 'name=>$self->{name}, '
		. 'frontend_obj=>$self, '
		. '); $backend_obj->init;';
	eval($init_string);
	if ($@) {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'Failed to init backend... ' . $@;
		$self->warn;
	}
	# make sure we got something that is defined and is a object of some sort
	if ( !defined($backend_obj) ) {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'Failed to init backend. Eval did not die, but returned value is undef';
		$self->warn;
	} elsif ( ref($backend_obj) eq '' || ref($backend_obj) eq 'ARRAY' || ref($backend_obj) eq 'HASH' ) {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'ref($backend_obj) is "' . ref($backend_obj) . '"';
		$self->warn;
	}

	$self->{backend_obj} = $backend_obj;
} ## end sub init_backend

=head2 ban

Bans the IP.

    $fw_helper->ban(ban => $ip);

=cut

sub ban {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data}=undef;

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 10;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /$IPv4_re/
		&& $opts{ban} !~ /$IPv6_re/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	eval { $self->{backend_obj}->ban( ban => $opts{ban} ); };
	if ($@) {
		$self->{error}       = 13;
		$self->{errorString} = 'banning item,"' . $opts{ban} . '", failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub ban

=head2 unban

Unbans the an IP.

    $fw_helper->unban(ban => $ip);

=cut

sub unban {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data}=undef;

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 10;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /$IPv4_re/
		&& $opts{ban} !~ /$IPv6_re/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	eval { $self->{backend_obj}->unban( ban => $opts{ban} ); };
	if ($@) {
		$self->{error}       = 14;
		$self->{errorString} = 'unbanning item,"' . $opts{ban} . '", failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub unban

=head2 list

List banned IPs.

    my @banned = $fw_helper->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data}=undef;

	my @banned;
	eval { @banned = $self->{backend_obj}->list; };
	if ($@) {
		$self->{error}       = 15;
		$self->{errorString} = 'listing bans failed... ' . $@;
		$self->warn;
		return;
	}

	return @banned;
} ## end sub list

=head2 re_init

Tells the backend to re-init it's self.

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data}=undef;

	eval { $self->{backend_obj}->re_init; };
	if ($@) {
		$self->{error}       = 16;
		$self->{errorString} = 'backend re_init failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data}=undef;

	eval { $self->{backend_obj}->teardown; };
	if ($@) {
		$self->{error}       = 17;
		$self->{errorString} = 'backend teardown failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub teardown

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, noBackendSpecified

No backend was specified to use.

=head2 2, invalidPortSpecified

Port is either not a positive int or a name that can be resolved by getservbyname.

=head2 3, portsNotArray

The data passed to new for ports is not an array.

=head2 4, protocolsNotArray

The data passed to new for protocols is not an array.

=head2 5, invalidPortSpecified

Port is either not a positive int or a name that can be resolved by getservbyname.

=head2 6, invalidPrefixSpecified

The specified prefix did not match /^[a-zA-Z0-9]+$/.

=head2 7, invalidName

The name is either undef or does not match /^[a-zA-Z0-9\-]+$/.

=head2 8, optionsNotHash

The item passed to new for options is not a hash.

=head2 9, noBanItem

No IP specified to ban.

=head2 10, banItemNotIP

The item to ban is not an IP. Either wrong ref type or regexp
test using L<Regexp::IPv4> and L<Regexp::IPv6> failed.

=head2 11, invalidBackend

The specified backend failed to pass a basic sanity check of making sure it
matches the regexp /^[a-zA-Z0-9\_]+$/.

=head2 12, backendInitError

Failed to init the backend.

=head2 13, banFailed

Failed to ban the item.

=head2 14, unbanFailed

Failed to unban the item.

=head2 15, listFailed

Failed get a list of bans.

=head2 16, reInitFailed

Failed to re_init the backend.

=head2 17, teardownFailed

Failed to teardown the backend.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-firewall-blockerhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Firewall::BlockerHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Firewall-BlockerHelper>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Firewall-BlockerHelper>

=item * Search CPAN

L<https://metacpan.org/release/Net-Firewall-BlockerHelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
