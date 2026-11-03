package Monitoring::Sneck::Checks::service;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::service - checks services are running

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests.
our $SYSTEMCTL = -x '/usr/bin/systemctl' ? '/usr/bin/systemctl' : '/bin/systemctl';
our $SERVICE   = '/usr/sbin/service';

=head1 SYNOPSIS

    web|perl:service -s nginx -s php-fpm -e
    www_jail|perl:service -s nginx -j www

=head1 DESCRIPTION

Checks each service given is running, and with --enabled, that it is
set to start at boot too. Any that is not is CRITICAL.

On Linux, systemctl is-active and is-enabled are asked, and on FreeBSD,
service status and service enabled, in a jail too with --jail. Other
OSes, or Linux without systemd, are UNKNOWN.

=head1 OPTIONS

- -s, --service :: A service. May be given more than once. Required.

- -e, --enabled :: They must also be enabled.

- -j, --jail :: On FreeBSD, check the services in this jail. UNKNOWN on
other OSes.

=cut

sub option_spec { return ( 'service|s=s@', 'enabled|e', 'jail|j=s' ) }

sub required { return ('service') }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $service ( @{ $options->{service} // [] } ) {
		push( @problems, '--service "' . $service . '" is not a service name' ) if $service !~ /\A[A-Za-z0-9_.\@:-]+\z/;
	}
	push( @problems, '--jail "' . $options->{jail} . '" is not a jail name or ID' )
		if defined( $options->{jail} ) && $options->{jail} !~ /\A[A-Za-z0-9_.-]+\z/;

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @problems;
	my @fine;
	foreach my $service ( @{ $self->opt('service') } ) {
		my ( $running, $state ) = $self->running($service);
		if ( !$running ) {
			push( @problems, $service . ' is ' . $state );
			next;
		}
		if ( $self->opt('enabled') && !$self->enabled($service) ) {
			push( @problems, $service . ' is running but not enabled' );
			next;
		}
		push( @fine, $service . ' ' . $state );
	} ## end foreach my $service ( @{ $self->opt('service') ...})
	my $where = defined( $self->opt('jail') ) ? ' in jail ' . $self->opt('jail') : '';

	return $self->finish( $self->CRITICAL, join( ', ', @problems ) . $where ) if defined( $problems[0] );
	return $self->finish( $self->OK,       join( ', ', @fine ) . $where );
} ## end sub check

=head2 running

Returns 1 and its state if a service is running, else 0 and its state,
such as inactive or failed. Dies if this OS is not supported.

=cut

sub running {
	my ( $self, $service ) = @_;

	if ( $self->os eq 'linux' ) {
		die("--jail is only for freebsd\n")                                if defined( $self->opt('jail') );
		die("systemctl is not there, so this host does not use systemd\n") if !-x $SYSTEMCTL;
		my ( $exit, $output ) = $self->run_command( $SYSTEMCTL, 'is-active', $service );
		my $state = ( split( /\n/, $output ) )[0] // 'unknown';

		# a unit that is not there is only inactive to is-active
		if ( $exit && $state eq 'inactive' ) {
			my ( undef, $load ) = $self->run_command( $SYSTEMCTL, 'show', '-p', 'LoadState', '--value', $service );
			$state = 'not there' if $load =~ /\Anot-found/;
		}
		return ( $exit ? 0 : 1, $state );
	} ## end if ( $self->os eq 'linux' )
	if ( $self->os eq 'freebsd' ) {
		my ( $exit, $output ) = $self->run_command( $SERVICE, $self->jail_args, $service, 'status' );
		return ( 1, 'running' ) if !$exit;
		return ( 0, $output =~ /does not exist|not found/i ? 'not there' : 'not running' );
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub running

=head2 enabled

Returns 1 if a service is enabled, else 0.

=cut

sub enabled {
	my ( $self, $service ) = @_;

	my ($exit)
		= $self->os eq 'linux'
		? $self->run_command( $SYSTEMCTL, 'is-enabled', $service )
		: $self->run_command( $SERVICE, $self->jail_args, $service, 'enabled' );

	return $exit ? 0 : 1;
} ## end sub enabled

=head2 jail_args

Returns the args for service to run in --jail, if given.

=cut

sub jail_args {
	my ($self) = @_;

	return defined( $self->opt('jail') ) ? ( '-j', $self->opt('jail') ) : ();
}

1;
