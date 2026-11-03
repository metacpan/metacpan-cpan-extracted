package Monitoring::Sneck::Checks::debsecan;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::debsecan - checks for Debian security fixes through debsecan

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where debsecan is. Set by tests.
our $DEBSECAN = '/usr/bin/debsecan';

# Where the suite is found if not given. Set by tests.
our $OS_RELEASE = '/etc/os-release';

# What it counts, the option letters for them, and the defaults, as check_debsecan.
our @KINDS = (
	{ name => 'fixed',    flag => 'fixed',          letter => 'f', warning => 20, critical => 30 },
	{ name => 'obsolete', flag => 'obsolete',       letter => 'o', warning => 1,  critical => 1 },
	{ name => 'high',     flag => 'high urgency',   letter => 'u', warning => 1,  critical => 1 },
	{ name => 'medium',   flag => 'medium urgency', letter => 'm', warning => 5,  critical => 10 },
	{ name => 'low',      flag => 'low urgency',    letter => 'l', warning => 10, critical => 20 },
);

=head1 SYNOPSIS

    !debsecan|interval=3600 timeout=300|perl:debsecan
    !debsecan_urgent|interval=3600 timeout=300|perl:debsecan -u 1 -U 1 -f 100 -F 200

=head1 DESCRIPTION

Runs debsecan and counts what it reports, the same as check_debsecan.
It is WARNING or CRITICAL once a count is at or over its limit.

- fixed :: Vulnerabilities with a fix ready to install.

- obsolete :: Installed packages Debian no longer has.

- high, medium, low :: Vulnerabilities by urgency.

By default only those with a fix are counted, as only those can be
acted on.

debsecan downloads the security tracker's data each time it runs,
which takes a while and should not be done every few minutes. Run it
as a compliance check with a interval of a hour or more and a longer
timeout, as in the synopsis. Set http_proxy through a env line if it
needs a proxy.

debsecan failing, such as not being able to reach the tracker, is
UNKNOWN. So is it not being there.

=head1 OPTIONS

- -s, --suite :: The Debian suite, such as trixie.
Default :: VERSION_CODENAME from /etc/os-release, else what debsecan picks

- -a, --all :: Count vulnerabilities with no fix yet too.

- -f, --fixed-warning and -F, --fixed-critical :: The WARNING and
CRITICAL limits for fixed.
Default :: 20, 30

- -o, --obsolete-warning and -O, --obsolete-critical :: The same for
obsolete.
Default :: 1, 1

- -u, --high-warning and -U, --high-critical :: The same for high
urgency.
Default :: 1, 1

- -m, --medium-warning and -M, --medium-critical :: The same for
medium urgency.
Default :: 5, 10

- -l, --low-warning and -L, --low-critical :: The same for low
urgency.
Default :: 10, 20

- -n, --lines :: How many of what it found to list after the status
line, once it is not OK.
Default :: 20

=cut

sub option_spec {
	return (
		'suite|s=s',
		'all|a',
		'lines|n=i',
		map {
			(
				$_->{name} . '-warning|' . $_->{letter} . '=i',
				$_->{name} . '-critical|' . uc( $_->{letter} ) . '=i'
			)
		} @KINDS
	);
} ## end sub option_spec

sub defaults {
	return {
		lines => 20,
		map { ( $_->{name} . '-warning' => $_->{warning}, $_->{name} . '-critical' => $_->{critical} ) } @KINDS
	};
}

sub validate {
	my ( $self, $options ) = @_;

	return ( '--suite "' . $options->{suite} . '" is not a suite' )
		if defined( $options->{suite} ) && $options->{suite} !~ /\A[a-z][a-z0-9-]*\z/;

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @command = ($DEBSECAN);
	my $suite   = $self->opt('suite') // $self->suite;
	push( @command, '--suite', $suite ) if defined($suite);
	push( @command, '--only-fixed' ) if !$self->opt('all');
	my ( $exit, $output ) = $self->run_command(@command);
	if ($exit) {
		my $first = ( split( /\n/, $output ) )[0] // '';
		return $self->finish( $self->UNKNOWN, 'debsecan exited ' . $exit . ', "' . $first . '"' );
	}

	# lines are "CVE-2025-1234 package (fixed, high urgency)", the flags in () being optional
	my %counts = map { $_->{name} => 0 } @KINDS;
	my @found;
	my %packages;
	foreach my $line ( split( /\n/, $output ) ) {
		next if $line !~ /\A(\S+)\s+(\S+)(?:\s+\((.*)\))?\s*\z/;
		my ( $vulnerability, $package, $flags ) = ( $1, $2, $3 // '' );
		my %has = map { $_ => 1 } split( /\s*,\s*/, $flags );
		$counts{ $_->{name} }++ foreach grep { $has{ $_->{flag} } } @KINDS;
		$packages{$package} = 1;
		push( @found, $line );
	}

	my $code = $self->OK;
	my @over;
	foreach my $kind (@KINDS) {
		my $count    = $counts{ $kind->{name} };
		my $warning  = $self->opt( $kind->{name} . '-warning' );
		my $critical = $self->opt( $kind->{name} . '-critical' );
		$self->perfdata(
			label    => $kind->{name},
			value    => $count,
			warning  => $warning,
			critical => $critical,
			min      => 0
		);
		if ( $count >= $critical ) {
			$code = $self->CRITICAL;
			push( @over, $kind->{name} );
		} elsif ( $count >= $warning ) {
			$code = $self->worst( $code, $self->WARNING );
			push( @over, $kind->{name} );
		}
	} ## end foreach my $kind (@KINDS)

	my $message
		= join( ', ', map { $_->{name} . ' ' . $counts{ $_->{name} } } @KINDS ) . ', in '
		. scalar( keys(%packages) )
		. ' packages'
		. ( defined($suite) ? ', ' . $suite : '' );
	$message = $message . ', too many ' . join( ', ', @over ) if defined( $over[0] );
	my @details;
	if ( $code != $self->OK ) {
		@details = splice( @found, 0, $self->opt('lines') );
		push( @details, 'and ' . scalar(@found) . ' more' ) if defined( $found[0] );
	}

	return $self->finish( $code, $message, @details );
} ## end sub check

=head2 suite

Returns VERSION_CODENAME from /etc/os-release, or undef if it has none.

=cut

sub suite {
	my $os_release = read_file( $OS_RELEASE, err_mode => 'quiet' ) // '';
	return $1 if $os_release =~ /^VERSION_CODENAME="?([a-z][a-z0-9-]*)"?\s*$/m;

	return undef;
}

1;
