package t::lib::MySimpleProcess;

use strict;
use Process ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'Process';
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
	unless ( $self->{run} ) {
		$self->{run} = 1;
	}
	return 1;
}

1;
