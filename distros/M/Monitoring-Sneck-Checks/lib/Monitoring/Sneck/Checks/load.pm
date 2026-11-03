package Monitoring::Sneck::Checks::load;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::load - checks the load averages

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    load|perl:load
    load_per_cpu|perl:load -r -w 1.5,1.2,1 -c 3,2.5,2

=head1 DESCRIPTION

Checks the 1, 5, and 15 minute load averages, the same as check_load.
Each is WARNING or CRITICAL if it is over its limit. On Linux they are
read from /proc, and on FreeBSD through L<BSD::Sysctl>. Other OSes are
UNKNOWN.

=head1 OPTIONS

- -w, --warning :: "1,5,15", the limits for each average.
Default :: 15,10,5

- -c, --critical :: "1,5,15", the limits for each average.
Default :: 30,25,20

- -r, --per-cpu :: Divide the averages by the number of CPUs first.

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s', 'per-cpu|r' ) }

sub defaults { return { warning => '15,10,5', critical => '30,25,20' } }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'warning', 'critical' ) {
		push( @problems, '--' . $name . ' must be three numbers, "1,5,15", such as 15,10,5' )
			if $options->{$name} !~ /\A[0-9.]+,[0-9.]+,[0-9.]+\z/;
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @averages = $self->averages;
	my $cpus     = $self->opt('per-cpu') ? $self->cpus : 1;
	@averages = map { sprintf( '%.2f', $_ / $cpus ) } @averages;
	my @warning  = split( /,/, $self->opt('warning') );
	my @critical = split( /,/, $self->opt('critical') );

	my $code = $self->OK;
	foreach my $index ( 0 .. 2 ) {
		my $average = $averages[$index];
		if ( $average > $critical[$index] ) {
			$code = $self->CRITICAL;
		} elsif ( $average > $warning[$index] ) {
			$code = $self->worst( $code, $self->WARNING );
		}
		$self->perfdata(
			label    => 'load' . ( 1, 5, 15 )[$index],
			value    => $average,
			warning  => $warning[$index],
			critical => $critical[$index],
			min      => 0
		);
	} ## end foreach my $index ( 0 .. 2 )

	my $message = 'load average ' . join( ', ', @averages );
	$message = $message . ' per CPU, of ' . $cpus if $self->opt('per-cpu');

	return $self->finish( $code, $message );
} ## end sub check

=head2 averages

Returns the 1, 5, and 15 minute load averages. Dies if they can not be
found.

=cut

sub averages {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my @averages = split( /\s+/, $self->proc_file('loadavg') );
		return @averages[ 0 .. 2 ];
	}
	if ( $self->os eq 'freebsd' ) {
		my $averages = $self->sysctl('vm.loadavg');
		return @{$averages}[ 0 .. 2 ];
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub averages

=head2 cpus

Returns the number of CPUs. Dies if it can not be found.

=cut

sub cpus {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my $cpus = () = $self->proc_file('cpuinfo') =~ /^processor\s*:/mg;
		return $cpus || 1;
	}
	if ( $self->os eq 'freebsd' ) {
		return $self->sysctl('hw.ncpu');
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub cpus

1;
