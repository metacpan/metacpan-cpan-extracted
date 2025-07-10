package Net::Firewall::BlockerHelper::backends::shell;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::shell - A shell backend for Net::Firewall::BlockHelper.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

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

    $fw_helper->init;

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
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		backend      => undef,
		options      => {},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		postfix      => undef,
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
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
			$self->{error}       = 3;
			$self->{errorString} = 'init is not blank';
			$self->warn;
		} elsif ( !defined( $opts{options}{teardown} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = 'teardown is not defined';
			$self->warn;
		} elsif ( $opts{options}{teardown} eq '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = 'teardown is not blank';
			$self->warn;
		} elsif ( !defined( $opts{options}{ban} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 5;
			$self->{errorString} = 'ban is not defined';
			$self->warn;
		} elsif ( $opts{options}{ban} eq '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 5;
			$self->{errorString} = 'ban is not blank';
			$self->warn;
		} elsif ( !defined( $opts{options}{unban} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 6;
			$self->{errorString} = 'unban is not defined';
			$self->warn;
		} elsif ( $opts{options}{unban} eq '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 5;
			$self->{errorString} = 'unban is not blank';
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

Initiates the backend.

No arguments are taken.

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
		if ( $? ne '0' ) {
			$self->{error}       = 12;
			$self->{errorString} = 'Init failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans the IP.

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
	} elsif ( $opts{ban} !~ /$IPv4_re/
		&& $opts{ban} !~ /$IPv6_re/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	my $command = $self->{options}{ban};
	$command =~ s/\%\%\%BAN\%\%\%/$opts{ban}/g;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? ne '0' ) {
			$self->{error}       = 13;
			$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans the an IP.

    $fw_helper->ban(ban => $ip);

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
	} elsif ( $opts{ban} !~ /$IPv4_re/
		&& $opts{ban} !~ /$IPv6_re/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	my $command = $self->{options}{unban};
	$command =~ s/\%\%\%BAN\%\%\%/$opts{ban}/g;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? ne '0' ) {
			$self->{error}       = 14;
			$self->{errorString} = 'Unban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 list

List banned IPs.

    my @banned = $fw_helper->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{frontend_obj}->{test_data} = 'list';

	return keys( %{ $self->{banned} } );
}

=head2 re_init

Tells the backend to re-init it's self.

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->teardown;
	$self->init;

	my @to_re_ban = keys( %{ $self->{banned} } );

	foreach my $item (@to_re_ban) {
		my $command = $self->{options}{ban};
		$command =~ s/\%\%\%BAN\%\%\%/$item/g;

		if ( !$self->{testing} ) {
			my $output = `$command 2>&1`;
			if ( $? ne '0' ) {
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

Tears down the setup for the backend.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->{inited} = 0;

	$self->errorblank;

	my $command = $self->{options}{teardown};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? ne '0' ) {
			$self->{error}       = 17;
			$self->{errorString} = 'Teardown failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{inited} = 0;
} ## end sub teardown

=head1 ERROR CODES / FLAGS

=head2 1, notInited

Backend has not been initted yet.

=head2 2, initInvalid

'init' for options hash is invalid. Either undef or blank.

=head 3, optionsUndef

Options is not a hash.

=head2 4, teardownInvalid

'teardown' for options hash is invalid. Either undef or blank.

=head2 5, banInvalid

'ban' for options hash is invalid. Either undef or blank.

=head2 6, unbanInvalid

'unban' for options hash is invalid. Either undef or blank.

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

=head2 18, alreadyInited

Backend has already been initiated.

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
