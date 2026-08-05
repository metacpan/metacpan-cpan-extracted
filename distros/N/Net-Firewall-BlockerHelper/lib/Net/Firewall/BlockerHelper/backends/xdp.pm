package Net::Firewall::BlockerHelper::backends::xdp;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::xdp - XDP/eBPF backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper::backends::xdp;

    my $backend;
    eval {
        $backend = Net::Firewall::BlockerHelper::backends::xdp->new(
                name    => 'derp',
                options => {
                          interfaces => ['eth0'],
                          },
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

    $backend->init;

    $backend->ban(ban=>'1.2.3.4');
    $backend->ban(ban=>'4.3.2.1');

    use Data::Dumper;
    print Dumper($backend->list);

    $backend->unban(ban=>'4.3.2.1');

    $backend->teardown;

=head1 DESCRIPTION

This backend drops packets using XDP/eBPF via the C<xdp-filter> tool from
xdp-tools.

C<xdp-filter> attaches an XDP program to one or more interfaces and maintains
an IP blocklist in a BPF map. This backend loads the program with a default
C<allow> policy so only the IPs explicitly added to the blocklist are dropped.

Requires C<xdp-filter> to be installed and in the C<PATH> of the process,
which must have sufficient privileges to run it.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: A hash of options to pass to the backend. See below for
            further info.
        - Default :: {}

    - ports :: Not used by this backend but is accepted for parity with
            Net::Firewall::BlockerHelper.
        - Default :: []

    - protocols :: Not used by this backend but is accepted for parity with
            Net::Firewall::BlockerHelper.
        - Default :: []

    - prefix :: Not used by this backend but is accepted for parity with
            Net::Firewall::BlockerHelper.
        - Default :: kur

    - name :: Not used but is required by Net::Firewall::BlockerHelper.
        - Default :: undef

The options hash accepts the following.

    - interfaces :: An array ref of interface names to load the XDP program
            onto, e.g. ['eth0']. This is required and must be a non-empty
            array ref.
        - Default :: undef

    - xdp_filter_cmd :: The path to the xdp-filter binary.
        - Default :: xdp-filter

    - mode :: The match mode passed to the 'ip' command via '-m', either
            'src' or 'dst'.
        - Default :: src

    - xdp_mode :: The XDP attach mode used when loading the program, passed to
            the 'load' command via '-m'. One of 'native', 'skb', 'hw', or
            'unspecified'.
        - Default :: native

All errors are considered fatal, meaning if new fails it will die.

    my $backend;
    eval {
        $backend = Net::Firewall::BlockerHelper::backends::xdp->new(
                name    => 'derp',
                options => {
                          interfaces => ['eth0'],
                          },
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
			# all_fatal is what Error::Helper 2.1.0 actually checks; all_errors_fatal
			# is kept for the name documented in its POD
			all_fatal        => 1,
			flags            => {
				1  => 'notInited',
				8  => 'optionsNotHash',
				9  => 'noBanItem',
				10 => 'banItemNotIP',
				12 => 'backendInitError',
				13 => 'banFailed',
				14 => 'unbanFailed',
				15 => 'listFailed',
				16 => 'reInitFailed',
				17 => 'teardownFailed',
				18 => 'alreadyInited',
				20 => 'modeInvalid',
				24 => 'checkFailed',
				25 => 'flushFailed',
				30 => 'interfacesInvalid',
				31 => 'banCidrFailed',
				32 => 'unbanCidrFailed',
				33 => 'cidrItemNotCidr',
				34 => 'cidrNotSupported',
				35 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options => {
			xdp_filter_cmd => 'xdp-filter',
			mode           => 'src',
			xdp_mode       => 'native',
		},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
		cidr_supported => 0,
	};
	bless $self;

	# used internally for testing
	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}
	if ( defined( $opts{frontend_obj} ) ) {
		$self->{frontend_obj} = $opts{frontend_obj};
	}

	if ( defined( $opts{options} ) ) {
		if ( ref( $opts{options} ) ne 'HASH' ) {
			$self->{perror}      = 1;
			$self->{error}       = 8;
			$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
			$self->warn;
			return $self;
		}

		# merge in the passed options, keeping the defaults for anything not set
		foreach my $key ( keys( %{ $opts{options} } ) ) {
			$self->{options}{$key} = $opts{options}{$key};
		}
	}

	# interfaces is required and must be a non-empty array ref
	if (   !defined( $self->{options}{interfaces} )
		|| ref( $self->{options}{interfaces} ) ne 'ARRAY'
		|| !@{ $self->{options}{interfaces} } )
	{
		$self->{perror} = 1;
		$self->{error}  = 30;
		$self->{errorString}
			= 'interfaces is required and must be a non-empty array ref';
		$self->warn;
		return $self;
	}

	# mode drives the 'ip' command's -m flag and must be src or dst
	my %valid_modes = ( src => 1, dst => 1 );
	if ( !$valid_modes{ $self->{options}{mode} } ) {
		$self->{perror} = 1;
		$self->{error}  = 20;
		$self->{errorString}
			= 'mode is "' . $self->{options}{mode} . '" and not one of "src" or "dst"';
		$self->warn;
		return $self;
	}

	$self->{name} = $opts{name};

	return $self;
} ## end sub new

=head2 init

Initiates the backend. For each configured interface this loads the
C<xdp-filter> program with the ipv4 and ipv6 features and a default C<allow>
policy, so only IPs added to the blocklist are dropped.

No arguments are taken.

If called a second time, it will error.

    $backend->init;

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my $cmd      = $self->{options}{xdp_filter_cmd};
	my $xdp_mode = $self->{options}{xdp_mode};

	my @commands;
	foreach my $iface ( @{ $self->{options}{interfaces} } ) {
		push( @commands,
			$cmd . ' load -f ipv4,ipv6 -p allow -m ' . $xdp_mode . ' ' . $iface );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $command (@commands) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 12;
				$self->{errorString}
					= 'Init failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the XDP blocklist by running
C<< xdp-filter ip <ip> -m <mode> >>. Banning an already banned IP is a noop.

    $backend->ban(ban => $ip);

=cut

sub ban {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

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
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/
		&& $opts{ban} !~ /\A$IPv6_re\z/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( $self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	my $command
		= $self->{options}{xdp_filter_cmd} . ' ip ' . $opts{ban} . ' -m ' . $self->{options}{mode};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 13;
			$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the XDP blocklist by running
C<< xdp-filter ip <ip> -m <mode> -r >>. Unbanning an IP that is not banned
is a noop.

    $backend->unban(ban => $ip);

=cut

sub unban {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

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
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/
		&& $opts{ban} !~ /\A$IPv6_re\z/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( !$self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'not banned';
		}
		return;
	}

	my $command
		= $self->{options}{xdp_filter_cmd} . ' ip ' . $opts{ban} . ' -m ' . $self->{options}{mode} . ' -r';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 14;
			$self->{errorString} = 'Unban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 34;
	$self->{errorString} = 'the ' . __PACKAGE__ . ' backend does not support CIDR bans';
	$self->warn;

	return;
} ## end sub ban_cidr

=head2 unban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->unban_cidr(ban => '1.2.3.0/24');

=cut

sub unban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 34;
	$self->{errorString} = 'the ' . __PACKAGE__ . ' backend does not support CIDR bans';
	$self->warn;

	return;
} ## end sub unban_cidr

=head2 list_cidr

CIDR bans are not supported by this backend, so this always returns an empty
list.

    my @banned_cidrs = $backend->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	return ();
}

=head2 list

List banned IPs. Returns an array of the currently banned IPs.

    my @banned = $backend->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list';
	}

	return keys( %{ $self->{banned} } );
}

=head2 re_init

Tells the backend to re-init it's self.

This will call teardown and init again. After that it will re-add all
previously added bans.

    $backend->re_init;

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from; init cleans up any remnants
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my @to_re_ban = keys( %{ $self->{banned} } );

	my @re_init_test_data;
	foreach my $item (@to_re_ban) {
		my $command
			= $self->{options}{xdp_filter_cmd} . ' ip ' . $item . ' -m ' . $self->{options}{mode};

		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 13;
				$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item (@to_re_ban)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend.

This will unload the XDP program from each configured interface.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my $cmd = $self->{options}{xdp_filter_cmd};

	my @commands;
	foreach my $iface ( @{ $self->{options}{interfaces} } ) {
		push( @commands, $cmd . ' unload ' . $iface );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $command (@commands) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 17;
				$self->{errorString} = 'Teardown failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	}
} ## end sub teardown

=head2 stop

Alias for L</teardown>, provided for parity with the fail2ban C<actionstop>
concept.

    $backend->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Runs C<xdp-filter status> to verify the setup is still in place. To be
considered healthy the command must exit zero and every configured interface
must be listed as loaded in its output; as the status is global, the exit
code alone would miss a single interface having been unloaded. This is the
equivalent of fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $command = $self->{options}{xdp_filter_cmd} . ' status';

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
		return 1;
	}

	my $output = `$command 2>&1`;
	if ( $? != 0 ) {
		return 0;
	}

	# the status is global, so make sure each configured interface is still
	# listed as loaded; a lone unloaded interface leaves the exit code zero
	foreach my $iface ( @{ $self->{options}{interfaces} } ) {
		if ( $output !~ /^\s*\Q$iface\E\s/m ) {
			return 0;
		}
	}

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by removing each one from the XDP
blocklist. This is the equivalent of fail2ban's C<actionflush>.

    $backend->flush;

=cut

sub flush {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	my @commands;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		push( @commands,
			$self->{options}{xdp_filter_cmd} . ' ip ' . $item . ' -m ' . $self->{options}{mode} . ' -r' );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $command (@commands) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 25;
				$self->{errorString} = 'Flush failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	}

	$self->{banned} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

=head2 8, optionsNotHash

The item passed to new for options is not a hash.

=head2 9, noBanItem

No IP specified to ban or unban.

=head2 10, banItemNotIP

The item to ban is not an IP. Either wrong ref type or regexp
test using L<Regexp::IPv4> and L<Regexp::IPv6> failed.

=head2 12, backendInitError

Failed to init the backend.

=head2 13, banFailed

Failed to ban the item.

=head2 14, unbanFailed

Failed to unban the item.

=head2 15, listFailed

Failed to get a list of bans.

=head2 16, reInitFailed

Failed to re_init the backend.

=head2 17, teardownFailed

Failed to teardown the backend.

=head2 18, alreadyInited

init called, but the backend has already been inited.

=head2 20, modeInvalid

The option mode is not 'src' or 'dst'.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 30, interfacesInvalid

The interfaces option is either undef, not an array ref, or an empty array
ref. It is required and must be a non-empty array ref.

=head2 31, banCidrFailed

Failed to ban the CIDR range.

=head2 32, unbanCidrFailed

Failed to unban the CIDR range.

=head2 33, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 34, cidrNotSupported

The backend does not support CIDR bans.

=head2 35, listCidrFailed

Failed to get a list of CIDR bans.

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
