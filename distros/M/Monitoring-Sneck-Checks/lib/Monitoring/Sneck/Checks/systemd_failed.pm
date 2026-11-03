package Monitoring::Sneck::Checks::systemd_failed;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::systemd_failed - checks for failed systemd units

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where systemctl is. Set by tests.
our $SYSTEMCTL = -x '/usr/bin/systemctl' ? '/usr/bin/systemctl' : '/bin/systemctl';

=head1 SYNOPSIS

    failed_units|perl:systemd_failed
    failed_units_most|perl:systemd_failed -x '^user@' -x 'flush\.service$'

=head1 DESCRIPTION

Lists the failed units through systemctl --failed, as a service that
crashed and stayed down. By default any is CRITICAL.

systemctl not being there, as on a host without systemd, or failing,
is UNKNOWN.

=head1 OPTIONS

- -x, --exclude :: A regex for units to leave out. May be given more
than once.

- -w, --warning :: Range for the number of failed units.

- -c, --critical :: Range for the number of failed units.
Default :: 0

=cut

sub option_spec { return ( 'exclude|x=s@', 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { critical => '0' } }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $regex ( @{ $options->{exclude} // [] } ) {
		push( @problems, '--exclude "' . $regex . '" is not a valid regex' ) if !eval { qr/$regex/; 1 };
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my ( $exit, $output ) = $self->run_command( $SYSTEMCTL, '--failed', '--plain', '--no-legend', '--no-pager' );
	return $self->finish( $self->UNKNOWN,
		'systemctl --failed exited ' . $exit . ', "' . ( ( split( /\n/, $output ) )[0] // '' ) . '"' )
		if $exit;

	my @excludes = @{ $self->opt('exclude') // [] };
	my @failed;
	foreach my $line ( split( /\n/, $output ) ) {
		my ($unit) = $line =~ /\A\s*\W?\s*(\S+\.\w+)\s/;
		next if !defined($unit) || grep { $unit =~ /$_/ } @excludes;
		push( @failed, $unit );
	}

	my $count = scalar(@failed);
	$self->perfdata(
		label    => 'failed',
		value    => $count,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my $message = $count . ' failed unit' . ( $count == 1 ? '' : 's' );
	$message = $message . ', ' . join( ', ', @failed ) if defined( $failed[0] );

	return $self->finish( $self->threshold_status( $count, $self->opt('warning'), $self->opt('critical') ), $message );
} ## end sub check

1;
