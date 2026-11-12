package Monitoring::Sneck::Checks::fail2ban;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::fail2ban - checks fail2ban's jails are up, and how many are banned

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where fail2ban-client is. Set by tests. Undef means the first of
# FAIL2BAN_CLIENT_PATHS that is there.
our $FAIL2BAN_CLIENT;
our @FAIL2BAN_CLIENT_PATHS = ( '/usr/bin/fail2ban-client', '/usr/local/bin/fail2ban-client' );

=head1 SYNOPSIS

    fail2ban|perl:fail2ban
    fail2ban_mail|perl:fail2ban -j sshd -j postfix -j dovecot
    fail2ban_attack|perl:fail2ban -j sshd -w 500 -c 2000

=head1 DESCRIPTION

Checks fail2ban is answering, the jails it has, and how many addresses
each has banned now, through fail2ban-client status, and status for
each jail.

- CRITICAL :: fail2ban not answering. A jail given with --jail not
running. The banned over --critical.

- WARNING :: No jails running. The banned over --warning.

- UNKNOWN :: fail2ban-client not being there, or not being allowed to
talk to fail2ban, as when not run as root.

The status line has the banned now for each jail. --warning and
--critical are for those added up, as a lot banned at once can be a
attack. The total failed and banned since fail2ban started are in the
perfdata as well.

=head1 OPTIONS

- -j, --jail :: A jail that must be running. May be given more than
once.

- -w, --warning :: Range for the banned now, of all jails.

- -c, --critical :: Range for the banned now, of all jails.

=cut

sub option_spec { return ( 'jail|j=s@', 'warning|w=s', 'critical|c=s' ) }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $client = $FAIL2BAN_CLIENT // ( grep { -x $_ } @FAIL2BAN_CLIENT_PATHS )[0];
	return $self->finish( $self->UNKNOWN, 'fail2ban-client is not there' ) if !defined($client);
	return $self->finish( $self->UNKNOWN, $client . ' is not there' )      if !-x $client;

	# such as "`- Jail list:	sshd, postfix", empty with no jails
	my $status = $self->client_status( $client, 'status' );
	return $status->{code} if defined( $status->{code} );
	my ($jail_list) = $status->{output} =~ /Jail list:[ \t]*(.*?)\s*$/m;
	return $self->finish( $self->UNKNOWN, 'fail2ban-client status did not list jails' ) if !defined($jail_list);
	my @jails = grep { $_ ne '' } split( /\s*,\s*/, $jail_list );

	my @codes = ( $self->OK );
	my @parts;
	my %running = map { $_ => 1 } @jails;
	foreach my $wanted ( @{ $self->opt('jail') // [] } ) {
		next if $running{$wanted};
		push( @codes, $self->CRITICAL );
		push( @parts, $wanted . ' not running' );
	}
	if ( !defined( $jails[0] ) ) {
		push( @codes, $self->WARNING );
		push( @parts, 'no jails running' );
		return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
	}

	my $banned_total = 0;
	my @banned_parts;
	foreach my $jail (@jails) {
		my $jail_status = $self->client_status( $client, 'status', $jail );
		return $jail_status->{code} if defined( $jail_status->{code} );

		# lines such as "|  |- Currently failed:	3" and "   |- Total banned:	15"
		my %counts;
		foreach my $count ( 'Currently failed', 'Total failed', 'Currently banned', 'Total banned' ) {
			( $counts{$count} ) = $jail_status->{output} =~ /\Q$count\E:\s*([0-9]+)/;
		}
		return $self->finish( $self->UNKNOWN, 'fail2ban-client status ' . $jail . ' did not say how many are banned' )
			if !defined( $counts{'Currently banned'} );

		$banned_total = $banned_total + $counts{'Currently banned'};
		push( @banned_parts, $jail . ' ' . $counts{'Currently banned'} );
		$self->perfdata( label => $jail . '_banned', value => $counts{'Currently banned'},      min => 0 );
		$self->perfdata( label => $jail . '_failed', value => $counts{'Currently failed'} // 0, min => 0 );
		$self->perfdata(
			label => $jail . '_total_banned',
			value => $counts{'Total banned'} // 0,
			uom   => 'c',
			min   => 0
		);
		$self->perfdata(
			label => $jail . '_total_failed',
			value => $counts{'Total failed'} // 0,
			uom   => 'c',
			min   => 0
		);
	} ## end foreach my $jail (@jails)

	push( @codes, $self->threshold_status( $banned_total, $self->opt('warning'), $self->opt('critical') ) );
	$self->perfdata(
		label    => 'banned',
		value    => $banned_total,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
	);
	# the banned for each jail goes last, so jails not running are not read as part of it
	unshift( @parts, scalar(@jails) . ' jail' . ( @jails == 1 ? '' : 's' ) );
	push( @parts, $banned_total . ' banned now: ' . join( ', ', @banned_parts ) );

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

=head2 client_status

Runs fail2ban-client with the args given, finishing the check if it
fails.

- client :: The path to fail2ban-client.

- args :: The args, such as 'status' or 'status', 'sshd'.

Returns a hash ref of output, what it printed, if it worked, or of
code, what finish returned, if it did not. Not being allowed to talk
to fail2ban is UNKNOWN, as it is a problem with how the check is run,
and anything else is CRITICAL, as fail2ban is not answering.

    my $status = $check->client_status( '/usr/bin/fail2ban-client', 'status' );
    return $status->{code} if defined( $status->{code} );
    # $status->{output} is "Status\n|- Number of jail:\t2\n`- Jail list:\tsshd, postfix\n"

=cut

sub client_status {
	my ( $self, $client, @args ) = @_;

	my ( $exit, $output ) = $self->run_command( $client, @args );
	return { output => $output } if !$exit;

	my $first = ( grep { /\S/ } split( /\n/, $output ) )[0] // 'saying nothing';
	$first =~ s/\AERROR\s+//;
	my $code = $output =~ /Permission denied/ ? $self->UNKNOWN : $self->CRITICAL;
	return { code =>
			$self->finish( $code, 'fail2ban-client ' . join( ' ', @args ) . ' exited ' . $exit . ', ' . $first ) };
} ## end sub client_status

1;
