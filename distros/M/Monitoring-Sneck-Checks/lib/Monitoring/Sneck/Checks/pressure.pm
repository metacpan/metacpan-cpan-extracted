package Monitoring::Sneck::Checks::pressure;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::pressure - checks Linux pressure stall information

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# What may be checked.
our @RESOURCES = ( 'cpu', 'memory', 'io' );

=head1 SYNOPSIS

    pressure|perl:pressure
    memory_pressure|perl:pressure -r memory -k full -w 5 -c 20
    io_pressure|perl:pressure -r io --io-warning 30 --io-critical 60 -a 300

=head1 DESCRIPTION

Checks the percent of time tasks were stalled waiting on CPU, memory,
or IO, from /proc/pressure. This tells being short of each apart in a
way load does not.

Each resource has some, the time at least one task was stalled, and
full, the time all were at once, which is the worse. Each is averaged
over 10, 60, and 300 seconds. full for CPU is always 0 for the system
as a whole, so it is left out.

Only Linux 4.20 and later have this, and only if not turned off with
psi=0. Others are UNKNOWN.

=head1 OPTIONS

- -r, --resource :: cpu, memory, or io. May be given more than once.
Default :: all three

- -k, --kind :: some or full.
Default :: some

- -a, --average :: 10, 60, or 300 seconds.
Default :: 60

- -w, --warning :: Range of percent stalled.
Default :: 20

- -c, --critical :: Range of percent stalled.
Default :: 50

- --cpu-warning, --cpu-critical, --memory-warning, --memory-critical,
--io-warning, --io-critical :: The same, for only that resource.

=cut

sub option_spec {
	return ( 'resource|r=s@', 'kind|k=s', 'average|a=i', 'warning|w=s', 'critical|c=s',
		map { ( $_ . '-warning=s', $_ . '-critical=s' ) } @RESOURCES );
}

sub defaults { return { kind => 'some', average => 60, warning => '20', critical => '50' } }

sub ranges {
	return ( 'warning', 'critical', map { ( $_ . '-warning', $_ . '-critical' ) } @RESOURCES );
}

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	my %known = map { $_ => 1 } @RESOURCES;
	foreach my $resource ( @{ $options->{resource} // [] } ) {
		push( @problems, '--resource "' . $resource . '" must be cpu, memory, or io' ) if !$known{$resource};
	}
	push( @problems, '--kind must be some or full' )      if $options->{kind}    !~ /\A(?:some|full)\z/;
	push( @problems, '--average must be 10, 60, or 300' ) if $options->{average} !~ /\A(?:10|60|300)\z/;
	push( @problems, 'nothing to check, as full is left out for cpu' )
		if $options->{kind} eq 'full'
		&& defined( $options->{resource} )
		&& !grep { $_ ne 'cpu' } @{ $options->{resource} };

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';
	my $kind    = $self->opt('kind');
	my $average = 'avg' . $self->opt('average');
	my @codes;
	my @parts;
	foreach my $resource ( @{ $self->opt('resource') // \@RESOURCES } ) {
		next if $resource eq 'cpu' && $kind eq 'full';
		my $content = eval { $self->proc_file( 'pressure/' . $resource ) };
		die("this kernel has no pressure stall information\n") if !defined($content);
		my ($line) = $content =~ /^\Q$kind\E (.*)$/m;
		my %values = ( $line // '' ) =~ /(\w+)=([0-9.]+)/g;
		die( 'can not make sense of /proc/pressure/' . $resource . "\n" ) if !defined( $values{$average} );

		my $warning  = $self->opt( $resource . '-warning' )  // $self->opt('warning');
		my $critical = $self->opt( $resource . '-critical' ) // $self->opt('critical');
		my $code     = $self->threshold_status( $values{$average}, $warning, $critical );
		push( @codes, $code );
		push( @parts, $resource . ' ' . $values{$average} . '%' );
		$self->perfdata(
			label    => $resource . '_' . $kind,
			value    => $values{$average},
			uom      => '%',
			warning  => $warning,
			critical => $critical,
			min      => 0,
			max      => 100
		);
	} ## end foreach my $resource ( @{ $self->opt('resource'...)})

	return $self->finish( $self->worst(@codes),
		$kind . ' stalled over ' . $self->opt('average') . ' seconds, ' . join( ', ', @parts ) );
} ## end sub check

1;
