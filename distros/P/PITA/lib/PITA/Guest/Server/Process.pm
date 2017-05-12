package PITA::Guest::Server::Process;

# A Process.pm compatible wrapper around PITA::Guest::Server

use 5.008;
use strict;
use Process ();

our $VERSION = '0.60';
our @ISA     = 'Process';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub pinged {
	$_[0]->{pinged};
}

sub mirrored {
	$_[0]->{mirrored};
}

sub uploaded {
	$_[0]->{uploaded};
}

# Find a single named upload
sub upload {
	my $self = shift;
	my $path = shift;
	foreach my $array ( @{$self->uploaded} ) {
		if ( $array->[0] eq $path ) {
			return $array->[1];
		}
	}
	return undef;
}





######################################################################
# Process Methods

sub prepare {
	my $self = shift;

	# Create the server object passing capitalised params in
	require PITA::Guest::Server;
	$self->{server} = PITA::Guest::Server->new(
		map { $_ => $self->{$_} } grep { /^[A-Z]/ } keys %$self
	);

	return 1;
}

sub run {
	my $self = shift;

	# Prepare to run POE
	require POE;
	POE->import;

	# Bootstrap the server and just hope for the best :)
	$self->{server}->start;
	POE::Kernel->run;

	return 1;
}

sub finish {
	my $self = shift;

	# Save the results and clean up the server
	if ( $self->{server} ) {
		$self->{pinged}   = $self->{server}->pinged;
		$self->{mirrored} = $self->{server}->mirrored;
		$self->{uploaded} = $self->{server}->uploaded;
		delete $self->{server};
	}

	return 1;
}

1;
