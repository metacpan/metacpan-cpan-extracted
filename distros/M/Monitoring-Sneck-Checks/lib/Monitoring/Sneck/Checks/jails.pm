package Monitoring::Sneck::Checks::jails;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::jails - checks FreeBSD jails and bhyve VMs are running

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests.
our $JLS         = '/usr/sbin/jls';
our $VM          = '/usr/local/sbin/vm';
our $JAIL_CONF   = '/etc/jail.conf';
our $JAIL_CONF_D = '/etc/jail.conf.d';

=head1 SYNOPSIS

    jails|perl:jails -a
    web_jails|perl:jails -j www -j db
    vms|perl:jails -v router -v nas

=head1 DESCRIPTION

Checks each jail given is running, through jls, and with
--all-configured, every jail defined in /etc/jail.conf and
/etc/jail.conf.d/*.conf. Each VM given with --vm must be running too,
through vm-bhyve's vm list. Any that is not is CRITICAL.
--all-configured finding no jails, or every one of them excluded, is
UNKNOWN, as there is nothing to check then.

Only FreeBSD has these, others are UNKNOWN.

=head1 OPTIONS

- -j, --jail :: A jail that must be running, by name. May be given more
than once.

- -a, --all-configured :: Every jail in jail.conf must be running.

- -x, --exclude :: A jail for --all-configured to leave out. May be
given more than once.

- -v, --vm :: A vm-bhyve VM that must be running. May be given more
than once.

One or more of --jail, --all-configured, or --vm must be given.

=cut

sub option_spec { return ( 'jail|j=s@', 'all-configured|a', 'exclude|x=s@', 'vm|v=s@' ) }

sub validate {
	my ( $self, $options ) = @_;

	return ('nothing to check, give --jail, --all-configured, or --vm')
		if !defined( $options->{jail} ) && !$options->{'all-configured'} && !defined( $options->{vm} );

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'freebsd';
	my @problems;
	my @unknown;
	my %wanted = map { $_ => 1 } @{ $self->opt('jail') // [] };
	if ( $self->opt('all-configured') ) {
		my @configured = $self->configured;
		push( @unknown, 'no jails configured in ' . $JAIL_CONF . ' or ' . $JAIL_CONF_D ) if !defined( $configured[0] );
		$wanted{$_} = 1 foreach @configured;
		delete( @wanted{ @{ $self->opt('exclude') // [] } } );
		push( @unknown, 'every configured jail is excluded' ) if defined( $configured[0] ) && !%wanted;
	}
	my $running_jails = 0;
	if (%wanted) {
		my ( $exit, $output ) = $self->run_command( $JLS, '-n', 'name' );
		return $self->finish( $self->UNKNOWN, 'jls exited ' . $exit ) if $exit;
		my %running = map { $_ => 1 } $output =~ /(?:^|\s)name=(\S+)/mg;
		$running_jails = scalar( keys(%running) );
		push( @problems, map { 'jail ' . $_ . ' is not running' } grep { !$running{$_} } sort( keys(%wanted) ) );
	}

	my $running_vms = 0;
	if ( defined( $self->opt('vm') ) ) {
		return $self->finish( $self->UNKNOWN, 'vm-bhyve is not there, ' . $VM ) if !-x $VM;
		my ( $exit, $output ) = $self->run_command( $VM, 'list' );
		return $self->finish( $self->UNKNOWN, 'vm list exited ' . $exit ) if $exit;

		# NAME DATASTORE LOADER CPU MEMORY VNC AUTO STATE, STATE being Running (PID) or Stopped
		my %states;
		foreach my $line ( split( /\n/, $output ) ) {
			my ($name) = $line =~ /\A(\S+)/;
			next if !defined($name) || $name eq 'NAME';
			$states{$name} = $line =~ /\bRunning\b/ ? 'running' : $line =~ /\bLocked\b/ ? 'locked' : 'stopped';
		}
		$running_vms = grep { $_ eq 'running' } values(%states);
		foreach my $vm ( @{ $self->opt('vm') } ) {
			next if ( $states{$vm} // '' ) eq 'running';
			push( @problems, 'VM ' . $vm . ' is ' . ( $states{$vm} // 'not there' ) );
		}
	} ## end if ( defined( $self->opt('vm') ) )

	my @parts;
	push( @parts, $running_jails . ' jails running' ) if %wanted;
	push( @parts, $running_vms . ' VMs running' )     if defined( $self->opt('vm') );
	push( @parts, @problems, @unknown );
	my @codes = ( defined( $problems[0] ) ? $self->CRITICAL : $self->OK );
	push( @codes, $self->UNKNOWN ) if defined( $unknown[0] );

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

=head2 configured

Returns the names of the jails defined in /etc/jail.conf and
/etc/jail.conf.d/*.conf.

=cut

sub configured {
	my ($self) = @_;

	my %names;
	foreach my $file ( $JAIL_CONF, glob( $JAIL_CONF_D . '/*.conf' ) ) {
		my $content = read_file( $file, err_mode => 'quiet' ) // next;
		$content =~ s/#[^\n]*//g;
		$content =~ s{/\*.*?\*/}{}gs;

		# "name {" at the top level, as parameters for all jails are set outside of any
		my $depth = 0;
	   # one token at a time, a name before a {, a brace, a quoted string, which may have braces in it, or anything else
		while ( $content
			=~ /\G(?:([A-Za-z0-9_.*-]+)\s*\{|(\{)|(\})|"(?:[^"\\]|\\.)*"|[A-Za-z0-9_.*-]+|[^{}A-Za-z0-9_.*"-]+)/gcs
			)
		{
			if ( defined($1) ) {
				$names{$1} = 1 if $depth == 0 && $1 ne '*';
				$depth++;
			} elsif ( defined($2) ) {
				$depth++;
			} elsif ( defined($3) ) {
				$depth-- if $depth;
			}
		} ## end while ( $content =~ ...)
	} ## end foreach my $file ( $JAIL_CONF, glob( $JAIL_CONF_D...))

	return sort( keys(%names) );
} ## end sub configured

1;
