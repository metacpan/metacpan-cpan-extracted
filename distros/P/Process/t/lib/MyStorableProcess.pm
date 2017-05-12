package t::lib::MyStorableProcess;

use strict;
use Process           ();
use Process::Storable ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = qw{
		Process::Storable
		Process
	};
}

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub prepare {
	my $self = shift;
	unless ( $self->{prepare} ) {
		$self->{prepare} = 1;
	}
	return 1
}

sub run {
	my $self = shift;
	foreach my $key ( sort keys %$self ) {
		print STDERR "$key=$self->{$key}\n";
	}
	unless ( $self->{run} ) {
		$self->{run} = 1;
	}
	return 1;
}

1;
