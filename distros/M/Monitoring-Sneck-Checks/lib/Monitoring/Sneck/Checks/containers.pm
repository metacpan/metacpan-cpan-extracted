package Monitoring::Sneck::Checks::containers;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::containers - checks Docker or Podman containers

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where the runtimes are. Set by tests.
our %RUNTIMES = ( docker => '/usr/bin/docker', podman => '/usr/bin/podman' );

=head1 SYNOPSIS

    containers|perl:containers
    web_containers|perl:containers -n web -n db -x '^buildkit'
    podman|perl:containers -r podman -n app

=head1 DESCRIPTION

Lists the containers through docker ps -a, or podman. A container
given with --name that is not running, or any running one whose health
check says it is unhealthy, is CRITICAL. One stuck restarting is
WARNING.

This needs access to the runtime, which for Docker means root or the
docker group. Not having it, or the runtime not being there, is
UNKNOWN.

=head1 OPTIONS

- -n, --name :: A container that must be running. May be given more
than once.

- -x, --exclude :: A regex for containers to leave out of the health
and restarting checks. May be given more than once.

- -r, --runtime :: docker or podman.
Default :: docker if it is there, else podman

=cut

sub option_spec { return ( 'name|n=s@', 'exclude|x=s@', 'runtime|r=s' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--runtime must be docker or podman' )
		if defined( $options->{runtime} ) && !$RUNTIMES{ $options->{runtime} };
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

	my $runtime = $self->opt('runtime') // ( -x $RUNTIMES{docker} ? 'docker' : 'podman' );
	my $command = $RUNTIMES{$runtime};
	return $self->finish( $self->UNKNOWN, $runtime . ' is not there' ) if !-x $command;
	my ( $exit, $output ) = $self->run_command( $command, 'ps', '-a', '--format', '{{.Names}}	{{.State}}	{{.Status}}' );
	if ($exit) {
		return $self->finish( $self->UNKNOWN,
			$runtime . ' ps exited ' . $exit . ', "' . ( ( split( /\n/, $output ) )[0] // '' ) . '"' );
	}

	my %containers;
	foreach my $line ( split( /\n/, $output ) ) {
		my ( $name, $state, $status ) = split( /\t/, $line );
		next if !defined($state);
		$containers{$name} = { state => lc($state), status => $status // '' };
	}

	my @excludes = @{ $self->opt('exclude') // [] };
	my @codes    = ( $self->OK );
	my @problems;
	foreach my $name ( @{ $self->opt('name') // [] } ) {
		my $container = $containers{$name};
		next if defined($container) && $container->{state} eq 'running';
		push( @codes,    $self->CRITICAL );
		push( @problems, $name . ' is ' . ( defined($container) ? $container->{state} : 'not there' ) );
	}
	foreach my $name ( sort( keys(%containers) ) ) {
		next if grep { $name =~ /$_/ } @excludes;
		my $container = $containers{$name};
		if ( $container->{state} eq 'running' && $container->{status} =~ /\(unhealthy\)/ ) {
			push( @codes,    $self->CRITICAL );
			push( @problems, $name . ' is unhealthy' );
		} elsif ( $container->{state} eq 'restarting' ) {
			push( @codes,    $self->WARNING );
			push( @problems, $name . ' is restarting' );
		}
	} ## end foreach my $name ( sort( keys(%containers) ) )

	my $running = grep { $_->{state} eq 'running' } values(%containers);
	$self->perfdata( label => 'running', value => $running, min => 0 );
	my $message = $running . ' of ' . scalar( keys(%containers) ) . ' containers running';
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

1;
