package Net::Firewall::BlockerHelper::backends::shell;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::shell - A shell backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

This backend just runs the commands configured via the options hash, so
what init, ban, and the like actually do is entirely up to the commands
supplied. Wiring them up to something that really blocks traffic is the
user's job. The example below just creates and removes files under C</tmp>
to show the flow and blocks nothing.

    use Net::Firewall::BlockerHelper;

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend=>'shell',
                name=>'derp',
                options=>{
                          init=>'mkdir /tmp/fw_helper_example/',
                          teardown=>'rm -rf /tmp/fw_helper_example/',
                          unban=>'rm -rf /tmp/fw_helper_example/%%%BAN%%%',
                          ban=>'touch /tmp/fw_helper_example/%%%BAN%%%',
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

    $fw_helper->init_backend;

    $fw_helper->ban(ban => '5.6.7.8');
    $fw_helper->ban(ban => '1.2.3.4');

    $fw_helper->unban(ban => '5.6.7.8');

    $fw_helper->teardown;

=head1 METHODS

=head2 new

Initiates the the object. Unlike other backends, this only takes uses
the options hash.

    - options :: A hash of options to pass to the backend.
        Default :: {}

    - name :: Not used but is required by Net::Firewall::BlockerHelper.
        Default :: undef

The values used for options is as below. All must be defined and can't be ''.
'2>&1' is appended to the end of the commands.

    - init :: The command to run to init the blocking.
         Default :: undef

    - teardown :: The command to run to teardown the blocking.
         Default :: undef

    - ban :: The command to run to ban a IP. %%%BAN%%% is replaced with the IP.
         Default :: undef

    - unban :: The command to run to un ban a IP. %%%BAN%%% is replaced with the IP.
         Default :: undef

    - check :: Optional command to run to verify the blocking is still in place.
         A zero exit is treated as healthy. If not defined, check always
         reports healthy.
         Default :: undef

    - flush :: Optional command to run to remove all bans at once. If not
         defined, flush falls back to unbanning each currently banned IP.
         Default :: undef

All errors are considered fatal, meaning if new fails it will die.

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend=>'shell',
                name=>'derp',
                options=>{
                          init=>'mkdir /tmp/fw_helper_example/',
                          teardown=>'rm -rf /tmp/fw_helper_example/',
                          unban=>'rm -rf /tmp/fw_helper_example/%%%BAN%%%',
                          ban=>'touch /tmp/fw_helper_example/%%%BAN%%%',
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
				2  => 'initInvalid',
				3  => 'optionsUndef',
				4  => 'teardownInvalid',
				5  => 'banInvalid',
				6  => 'unbanInvalid',
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
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'banCidrFailed',
				27 => 'unbanCidrFailed',
				28 => 'cidrItemNotCidr',
				29 => 'cidrNotSupported',
				30 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		backend        => undef,
		options        => {},
		ports          => [],
		protocols      => [],
		testing        => undef,
		test_data      => undef,
		prefix         => 'kur',
		frontend_obj   => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
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
		}
		$self->{options} = $opts{options};

		if ( !defined( $opts{options}{init} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 2;
			$self->{errorString} = 'init is not defined';
			$self->warn;
		} elsif ( $opts{options}{init} eq '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 2;
			$self->{errorString} = 'init is blank';
			$self->warn;
		} elsif ( !defined( $opts{options}{teardown} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = 'teardown is not defined';
			$self->warn;
		} elsif ( $opts{options}{teardown} eq '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = 'teardown is blank';
			$self->warn;
		} elsif ( !defined( $opts{options}{ban} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 5;
			$self->{errorString} = 'ban is not defined';
			$self->warn;
		} elsif ( $opts{options}{ban} eq '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 5;
			$self->{errorString} = 'ban is blank';
			$self->warn;
		} elsif ( !defined( $opts{options}{unban} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 6;
			$self->{errorString} = 'unban is not defined';
			$self->warn;
		} elsif ( $opts{options}{unban} eq '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 6;
			$self->{errorString} = 'unban is blank';
			$self->warn;
		}
	} else {
		if ( ref( $opts{options} ) ne 'HASH' ) {
			$self->{perror}      = 1;
			$self->{error}       = 3;
			$self->{errorString} = 'options is undef and not a hash';
			$self->warn;
		}
	}

	return $self;
} ## end sub new

=head2 init

Initiates the backend by running the configured C<init> command with
'2>&1' appended. A non-zero exit is an error.

Note that what this actually sets up is entirely down to the configured
command. See L</SYNOPSIS>.

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

	my $command = $self->{options}{init};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 12;
			$self->{errorString} = 'Init failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then the configured C<ban> command is run with %%%BAN%%%
replaced by the IP. A non-zero exit is an error.

    $fw_helper->ban(ban => $ip);

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

	my $command = $self->{options}{ban};
	$command =~ s/\%\%\%BAN\%\%\%/$opts{ban}/g;

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
and lowercased, then the configured C<unban> command is run with %%%BAN%%%
replaced by the IP. A non-zero exit is an error.

    $fw_helper->unban(ban => $ip);

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

	my $command = $self->{options}{unban};
	$command =~ s/\%\%\%BAN\%\%\%/$opts{ban}/g;

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

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased, then the configured C<ban> command is run with
%%%BAN%%% replaced by the CIDR.

    $fw_helper->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
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
		$self->{error}       = 28;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 28;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	my $command = $self->{options}{ban};
	$command =~ s/\%\%\%BAN\%\%\%/$opts{ban}/g;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 26;
			$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased, then the configured C<unban> command is run with
%%%BAN%%% replaced by the CIDR.

    $fw_helper->unban_cidr(ban => '1.2.3.0/24');

=cut

sub unban_cidr {
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
		$self->{error}       = 28;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 28;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	my $command = $self->{options}{unban};
	$command =~ s/\%\%\%BAN\%\%\%/$opts{ban}/g;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 27;
			$self->{errorString} = 'Unban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR
ranges. Single IPs are not included; for those see L</list>.

    my @banned_cidrs = $fw_helper->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list_cidr';
	}

	return keys( %{ $self->{banned_cidr} } );
}

=head2 list

List banned IPs. Returns an array of the currently banned single IPs. CIDR
ranges are not included; for those see L</list_cidr>.

    my @banned = $fw_helper->list;

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

This will call teardown and init again, re-running the configured
C<teardown> and C<init> commands. teardown is best effort. After that the
configured C<ban> command is re-run for every previously banned IP and CIDR
range.

    $fw_helper->re_init;

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from; init cleans up any remnants
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	# both single IPs and CIDR ranges are re-added the same way
	my @to_re_ban = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	foreach my $item (@to_re_ban) {
		my $command = $self->{options}{ban};
		$command =~ s/\%\%\%BAN\%\%\%/$item/g;

		if ( !$self->{testing} ) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 13;
				$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $items (@to_re_ban)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 're-inited';
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend by running the configured C<teardown>
command. A non-zero exit is an error.

    $fw_helper->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my $command = $self->{options}{teardown};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 17;
			$self->{errorString} = 'Teardown failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}
} ## end sub teardown

=head2 stop

Alias for L</teardown>, provided for parity with the fail2ban C<actionstop>
concept.

    $fw_helper->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Runs the optional C<check> command from the options hash. A zero exit code
is treated as healthy. If no C<check> command was configured, this always
reports healthy. This is the equivalent of fail2ban's C<actioncheck>.

    if ( !$fw_helper->check ) {
        $fw_helper->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# no check command configured -> assume healthy
	if ( !defined( $self->{options}{check} ) || $self->{options}{check} eq '' ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'check';
		}
		return 1;
	}

	my $command = $self->{options}{check};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
		return 1;
	}

	my $output = `$command 2>&1`;
	return $? == 0 ? 1 : 0;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once. If a C<flush> command was
configured in the options hash it is run; otherwise it falls back to
unbanning each currently banned IP. This is the equivalent of fail2ban's
C<actionflush>.

    $fw_helper->flush;

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

	if ( defined( $self->{options}{flush} ) && $self->{options}{flush} ne '' ) {
		my $command = $self->{options}{flush};

		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = $command;
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 25;
				$self->{errorString} = 'Flush failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}

		$self->{banned}      = {};
		$self->{banned_cidr} = {};
	} else {
		# no bulk flush command configured -> unban each currently banned IP
		foreach my $item ( keys( %{ $self->{banned} } ) ) {
			$self->unban( ban => $item );
		}
		foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
			$self->unban_cidr( ban => $item );
		}
	}
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

=head2 2, initInvalid

The option init is undef or blank.

=head2 3, optionsUndef

The options hash passed to new is undef.

=head2 4, teardownInvalid

The option teardown is undef or blank.

=head2 5, banInvalid

The option ban is undef or blank.

=head2 6, unbanInvalid

The option unban is undef or blank.

=head2 8, optionsNotHash

The item passed to new for options is not a hash.

=head2 9, noBanItem

No IP or CIDR range specified to ban or unban.

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

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, banCidrFailed

Failed to ban the CIDR range.

=head2 27, unbanCidrFailed

Failed to unban the CIDR range.

=head2 28, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 29, cidrNotSupported

The backend does not support CIDR bans.

=head2 30, listCidrFailed

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
