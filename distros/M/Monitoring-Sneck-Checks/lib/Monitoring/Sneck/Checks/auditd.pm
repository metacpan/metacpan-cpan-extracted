package Monitoring::Sneck::Checks::auditd;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);
use Digest::SHA qw(sha256_hex);

=head1 NAME

Monitoring::Sneck::Checks::auditd - checks Linux auditing is on, with the rules it should have

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where auditctl is. Set by tests. Undef means the first of AUDITCTL_PATHS
# that is there.
our $AUDITCTL;
our @AUDITCTL_PATHS = ( '/sbin/auditctl', '/usr/sbin/auditctl' );

=head1 SYNOPSIS

    auditd|perl:auditd
    auditd_cis|perl:auditd -I
    auditd_hash|perl:auditd -H 3b8d6f0e5a2c4b19d7e8f6a5c3b2a1908f7e6d5c4b3a29180f7e6d5c4b3a2918
    auditd_rules|perl:auditd -r /etc/sneck/audit.rules.loaded

=head1 DESCRIPTION

Checks auditd is running, auditing is enabled, and what rules are
loaded, through auditctl -s and auditctl -l.

- CRITICAL :: auditd not running. Auditing disabled. Rules missing from,
or not in, --rules-file. The rules not matching --hash. Lost events
over --lost-critical.

- WARNING :: The rules not immutable, with --immutable. Lost events
over --lost-warning.

- UNKNOWN :: Not being Linux, auditctl not being there, or failing, as
it does when not run as root.

The file for --rules-file is as auditctl -l prints them, so can be made
with auditctl -l > $file once the rules are as wanted. Blank lines and
those starting with # are skipped. Order is not compared.

The hash for --hash is the SHA-256 of what auditctl -l prints, the
same as auditctl -l | sha256sum gives. The current one is on a line
after the status line, so it can be taken from a run on a host with the
rules as wanted. Use --rules-file instead to see which rules differ.

Lost is the events the kernel dropped since boot, such as when the
backlog filled.

=head1 OPTIONS

- -r, --rules-file :: A file of the rules there must be, and no others.

- -H, --hash :: The SHA-256 the rules must have, in hex.

- -I, --immutable :: WARNING if the rules are not locked with -e 2.

- --lost-warning :: Range for lost events.

- --lost-critical :: Range for lost events.

=cut

sub option_spec {
	return ( 'rules-file|r=s', 'hash|H=s', 'immutable|I', 'lost-warning=s', 'lost-critical=s' );
}

sub ranges { return ( 'lost-warning', 'lost-critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	return ('--hash must be a SHA-256, 64 hex digits')
		if defined( $options->{hash} ) && $options->{hash} !~ /\A[0-9a-fA-F]{64}\z/;

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';
	my $auditctl = $AUDITCTL // ( grep { -x $_ } @AUDITCTL_PATHS )[0];
	return $self->finish( $self->UNKNOWN, 'auditctl is not there' )     if !defined($auditctl);
	return $self->finish( $self->UNKNOWN, $auditctl . ' is not there' ) if !-x $auditctl;

	# lines such as "enabled 1", "pid 1234", and "lost 0"
	my ( $status_exit, $status_output ) = $self->run_command( $auditctl, '-s' );
	my %status;
	foreach my $line ( split( /\n/, $status_output ) ) {
		$status{$1} = $2 if $line =~ /\A(\S+) (\S+)/;
	}
	if ( $status_exit || !defined( $status{enabled} ) ) {
		my $first = ( grep { /\S/ } split( /\n/, $status_output ) )[0] // 'saying nothing';
		return $self->finish( $self->UNKNOWN, 'auditctl -s exited ' . $status_exit . ', ' . $first );
	}
	my ( $rules_exit, $rules_output ) = $self->run_command( $auditctl, '-l' );
	if ($rules_exit) {
		my $first = ( grep { /\S/ } split( /\n/, $rules_output ) )[0] // 'saying nothing';
		return $self->finish( $self->UNKNOWN, 'auditctl -l exited ' . $rules_exit . ', ' . $first );
	}
	my @rules = grep { /\S/ && $_ ne 'No rules' } split( /\n/, $rules_output );

	my @codes = ( $self->OK );
	my @parts;
	my @details;
	if ( !$status{pid} ) {
		push( @codes, $self->CRITICAL );
		push( @parts, 'auditd not running' );
	}
	# 0 is disabled, 1 enabled, and 2 enabled with the rules locked until reboot
	if ( $status{enabled} eq '0' ) {
		push( @codes, $self->CRITICAL );
		push( @parts, 'auditing disabled' );
	} elsif ( $status{enabled} eq '2' ) {
		push( @parts, 'auditing enabled and immutable' );
	} else {
		push( @parts, 'auditing enabled' );
		if ( $self->opt('immutable') ) {
			push( @codes, $self->WARNING );
			push( @parts, 'rules not immutable' );
		}
	}

	push( @parts, scalar(@rules) . ' rule' . ( @rules == 1 ? '' : 's' ) );

	if ( defined( $self->opt('rules-file') ) ) {
		my $wanted_text = read_file( $self->opt('rules-file'), err_mode => 'quiet' );
		return $self->finish( $self->UNKNOWN, 'can not read ' . $self->opt('rules-file') . ', ' . $! )
			if !defined($wanted_text);
		my @wanted     = grep { /\S/ && !/\A\s*#/ } split( /\n/, $wanted_text );
		my %loaded     = map  { $_ => 1 } @rules;
		my %wanted     = map  { $_ => 1 } @wanted;
		my @missing    = grep { !$loaded{$_} } @wanted;
		my @unexpected = grep { !$wanted{$_} } @rules;
		if ( @missing || @unexpected ) {
			push( @codes,   $self->CRITICAL );
			push( @parts,   scalar(@missing) . ' missing, ' . scalar(@unexpected) . ' unexpected' );
			push( @details, map { 'missing: ' . $_ } @missing );
			push( @details, map { 'unexpected: ' . $_ } @unexpected );
		}
	} ## end if ( defined( $self->opt('rules-file') ) )

	# of the output as is, so it matches auditctl -l | sha256sum
	my $hash = sha256_hex($rules_output);
	if ( defined( $self->opt('hash') ) && lc( $self->opt('hash') ) ne $hash ) {
		push( @codes, $self->CRITICAL );
		push( @parts, 'rules hash differs' );
	}
	push( @details, 'rules sha256 ' . $hash );

	my $lost      = $status{lost} // 0;
	my $lost_code = $self->threshold_status( $lost, $self->opt('lost-warning'), $self->opt('lost-critical') );
	push( @codes, $lost_code );
	push( @parts, $lost . ' lost' ) if $lost || $lost_code != $self->OK;
	$self->perfdata( label => 'rules', value => scalar(@rules), min => 0 );
	$self->perfdata(
		label    => 'lost',
		value    => $lost,
		uom      => 'c',
		warning  => $self->opt('lost-warning'),
		critical => $self->opt('lost-critical'),
		min      => 0,
	);

	return $self->finish( $self->worst(@codes), join( ', ', @parts ), @details );
} ## end sub check

1;
