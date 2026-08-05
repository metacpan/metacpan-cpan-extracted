package Net::Firewall::BlockerHelper::backends::file_reload;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::file_reload - Render banned IPs to a file and run a reload hook.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

The rendered file has no effect on its own; whatever is meant to consume it
must be configured to read it and the C<reload> option set to whatever
makes it re-read it. So for the nginx example below, nginx needs a line
like the following in the relevant C<http> or C<server> context.

    include /etc/nginx/blocklist.conf;

Also worth noting is that with C<remove_on_teardown> left at its default
of 1, teardown unlinks the file, so a consumer that errors on a missing
include, nginx included, will then fail to reload or start till the file
exists again. For consumers like that either set C<remove_on_teardown>
to 0, which leaves an empty file in place instead, or make sure the file
gets created before the consumer needs it.

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'file_reload',
        name    => 'blocklist',
        options => {
            file   => '/etc/nginx/blocklist.conf',
            format => 'deny %%%BAN%%%;',
            reload => 'systemctl reload nginx',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );
    $fw_helper->teardown;

=head1 DESCRIPTION

This is a generic backend for anything that reads a list of IPs from a file
and needs to be told to reload after that file changes: web servers, DNS RPZ
zones, hand rolled ipset restore files, and so on.

The full set of currently banned IPs is rendered to C<file> from in-memory
state on every change; the file is never parsed back, so this module is the
sole author of its contents. After each write the optional C<reload> command
is run. Because the file is rewritten wholesale, ban/unban are idempotent and
there is never any partially applied state.

=head1 METHODS

=head2 new

    - options :: A hash of options. See below.
        - Default :: {}

    - name :: Required by Net::Firewall::BlockerHelper, otherwise unused.
        - Default :: undef

The options hash accepts the following.

    - file :: Path of the file to render the banned IPs to. Required.
        - Default :: undef

    - reload :: Command run after the file is written. '2>&1' is appended.
            If undef or blank, nothing is run and only the file is updated.
        - Default :: undef

    - blank_reload_error :: If true, the reload command producing no output
            at all is treated as a failure, even with a zero exit. Set to 0
            for reload commands that are silent on success, such as
            'systemctl reload nginx'.
        - Default :: 1

    - format :: Per-IP line template. '%%%BAN%%%' is replaced with the IP.
            The rendered lines are newline joined.
        - Default :: '%%%BAN%%%'

    - header :: String emitted at the top of the file, before the IP lines.
        - Default :: ''

    - footer :: String emitted at the bottom of the file, after the IP lines.
        - Default :: ''

    - check :: Optional command used by check(). A zero exit is healthy. If
            not set, check() verifies the file still exists instead.
        - Default :: undef

    - remove_on_teardown :: If true, teardown unlinks the file. If false, the
            file is rendered empty (header/footer only) and left in place.
        - Default :: 1

All errors are considered fatal, meaning if new fails it will die.

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
				24 => 'checkFailed',
				25 => 'flushFailed',
				30 => 'fileNotDefined',
				31 => 'fileWriteFailed',
				32 => 'banCidrFailed',
				33 => 'unbanCidrFailed',
				34 => 'cidrItemNotCidr',
				35 => 'cidrNotSupported',
				36 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options      => {},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		name         => undef,
		frontend_obj   => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
	};
	bless $self;

	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}
	if ( defined( $opts{frontend_obj} ) ) {
		$self->{frontend_obj} = $opts{frontend_obj};
	}
	if ( defined( $opts{name} ) ) {
		$self->{name} = $opts{name};
	}

	if ( defined( $opts{options} ) && ref( $opts{options} ) ne 'HASH' ) {
		$self->{perror}      = 1;
		$self->{error}       = 8;
		$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
		$self->warn;
	} elsif ( defined( $opts{options} ) ) {
		$self->{options} = $opts{options};
	}

	# file is the one hard requirement
	if ( !defined( $self->{options}{file} ) || $self->{options}{file} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'options{file} is undef or blank';
		$self->warn;
	}

	# fill in the templating defaults
	$self->{options}{format} = '%%%BAN%%%' if ( !defined( $self->{options}{format} ) );
	$self->{options}{header} = ''          if ( !defined( $self->{options}{header} ) );
	$self->{options}{footer} = ''          if ( !defined( $self->{options}{footer} ) );
	$self->{options}{remove_on_teardown} = 1
		if ( !defined( $self->{options}{remove_on_teardown} ) );
	$self->{options}{blank_reload_error} = 1
		if ( !defined( $self->{options}{blank_reload_error} ) );

	return $self;
} ## end sub new

# Internal helper. Builds the full file contents from the current ban list,
# sorted so the output is stable, wrapped in the configured header/footer.
sub _render {
	my ($self) = @_;

	my @lines;
	push( @lines, $self->{options}{header} ) if ( $self->{options}{header} ne '' );

	# single IPs and CIDR ranges are rendered into the same file the same way
	my @to_render = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );
	foreach my $ip ( sort(@to_render) ) {
		my $line = $self->{options}{format};
		$line =~ s/\%\%\%BAN\%\%\%/$ip/g;
		push( @lines, $line );
	}

	push( @lines, $self->{options}{footer} ) if ( $self->{options}{footer} ne '' );

	return join( "\n", @lines ) . "\n";
} ## end sub _render

# Internal helper. Renders the file and runs the reload hook. In testing mode
# it records what would happen in test_data instead of touching the disk. The
# $error_flag is the error code to raise on a write/reload failure so the
# caller's context (ban vs unban vs ...) is preserved.
sub _apply {
	my ( $self, $error_flag ) = @_;

	my $content = $self->_render;
	my $reload  = $self->{options}{reload};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = {
			file    => $self->{options}{file},
			content => $content,
			reload  => $reload,
		};
		return;
	}

	my $fh;
	if ( !open( $fh, '>', $self->{options}{file} ) ) {
		$self->{error}       = 31;
		$self->{errorString} = 'could not open "' . $self->{options}{file} . '" for writing... ' . $!;
		$self->warn;
		return;
	}
	print( $fh $content );
	close($fh);

	if ( defined($reload) && $reload ne '' ) {
		my $output = `$reload 2>&1`;
		$output = '' if ( !defined($output) );
		if ( $? != 0 ) {
			$self->{error}       = $error_flag;
			$self->{errorString} = 'reload command "' . $reload . '" failed... ' . $output;
			$self->warn;
		} elsif ( $self->{options}{blank_reload_error} && $output !~ /\S/ ) {
			$self->{error} = $error_flag;
			$self->{errorString}
				= 'reload command "' . $reload . '" produced no output and blank_reload_error is true';
			$self->warn;
		}
	}

	return;
} ## end sub _apply

=head2 init

Initiates the backend, rendering an initial (empty unless bans were
pre-seeded) file and running the reload hook.

Note that the consumer must be configured to read the rendered file for any
of this to have an effect. See L</SYNOPSIS>.

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	$self->_apply(12);

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the ban list. The file is re-rendered and the
reload command, if one is configured, is run. Banning an already banned IP
is a noop.

    $fw_helper->ban( ban => $ip );

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

	$self->{banned}{ $opts{ban} } = 1;
	$self->_apply(13);
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the ban list. The file is re-rendered
without it and the reload command, if one is configured, is run. Unbanning
an IP that is not banned is a noop.

    $fw_helper->unban( ban => $ip );

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

	delete( $self->{banned}{ $opts{ban} } );
	$self->_apply(14);
} ## end sub unban

# Internal helper. Returns a true value if the passed scalar is a valid IPv4 or
# IPv6 CIDR range, that is an address followed by "/" and a prefix length that
# is within the range valid for its family (0 to 32 for IPv4, 0 to 128 for
# IPv6). Returns false otherwise.
sub _valid_cidr {
	my ( $self, $cidr ) = @_;

	return 0 if ( !defined($cidr) || ref($cidr) ne '' );

	if ( $cidr =~ m!\A(.+)/([0-9]{1,3})\z! ) {
		my ( $addr, $prefix ) = ( $1, $2 );
		return 1 if ( $addr =~ /\A$IPv4_re\z/ && $prefix <= 32 );
		return 1 if ( $addr =~ /\A$IPv6_re\z/ && $prefix <= 128 );
	}

	return 0;
} ## end sub _valid_cidr

=head2 ban_cidr

Bans a CIDR range by rendering it into the file the same way a single IP is.

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
		$self->{error}       = 34;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 34;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( $self->{banned_cidr}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
	$self->_apply(32);
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by re-rendering the file without it.

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
		$self->{error}       = 34;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 34;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( !$self->{banned_cidr}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'not banned';
		}
		return;
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
	$self->_apply(33);
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges.

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

Re-renders the file from the retained ban list and runs the reload hook. As
the file is always rendered from full state, nothing needs tearing down
first; a single re-render restores everything.

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

	# render the current ban list back out; the file is authored purely from
	# state so this restores everything in one write
	$self->_apply(16);

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Removes the rendered file (or empties it when remove_on_teardown is false)
and runs the reload hook.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	if ( $self->{options}{remove_on_teardown} ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = {
				file    => $self->{options}{file},
				content => undef,
				reload  => $self->{options}{reload},
			};
		} else {
			# unlink is best effort; a missing file is already the desired state
			unlink( $self->{options}{file} );
			my $reload = $self->{options}{reload};
			if ( defined($reload) && $reload ne '' ) {
				my $output = `$reload 2>&1`;
				$output = '' if ( !defined($output) );
				if ( $? != 0 ) {
					$self->{error}       = 17;
					$self->{errorString} = 'reload command "' . $reload . '" failed... ' . $output;
					$self->warn;
				} elsif ( $self->{options}{blank_reload_error} && $output !~ /\S/ ) {
					$self->{error} = 17;
					$self->{errorString}
						= 'reload command "' . $reload . '" produced no output and blank_reload_error is true';
					$self->warn;
				}
			}
		}
		return;
	} ## end if ( $self->{options}{remove_on_teardown...})

	# leave an empty (header/footer only) file behind; both the single IP and
	# CIDR state are stashed so the empty render omits them but they survive
	my %saved_banned      = %{ $self->{banned} };
	my %saved_banned_cidr = %{ $self->{banned_cidr} };
	$self->{banned}      = {};
	$self->{banned_cidr} = {};
	$self->_apply(17);
	$self->{banned}      = \%saved_banned;
	$self->{banned_cidr} = \%saved_banned_cidr;
} ## end sub teardown

=head2 stop

Alias for L</teardown>.

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

If a C<check> command is configured, runs it and treats a zero exit as
healthy. Otherwise verifies the rendered file still exists.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( defined( $self->{options}{check} ) && $self->{options}{check} ne '' ) {
		my $command = $self->{options}{check};
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = $command;
			return 1;
		}
		my $output = `$command 2>&1`;
		return $? == 0 ? 1 : 0;
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'check';
		return 1;
	}

	return ( -e $self->{options}{file} ) ? 1 : 0;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by clearing the ban list and
re-rendering the now empty file.

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

	# the file is re-rendered from full state, so clearing both hashes removes
	# every single IP and CIDR ban at once
	$self->{banned}      = {};
	$self->{banned_cidr} = {};
	$self->_apply(25);
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

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

=head2 30, fileNotDefined

The option file is undef or blank.

=head2 31, fileWriteFailed

Could not open the file for writing.

=head2 32, banCidrFailed

Failed to ban the CIDR range.

=head2 33, unbanCidrFailed

Failed to unban the CIDR range.

=head2 34, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 35, cidrNotSupported

The backend does not support CIDR bans.

=head2 36, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::file_reload
