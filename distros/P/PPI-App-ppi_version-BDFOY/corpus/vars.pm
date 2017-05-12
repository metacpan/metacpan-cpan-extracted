package Tie::Timely;
use strict;

use Carp qw(croak);
use vars qw($VERSION);

$VERSION = '1.001';

sub TIESCALAR {
	my $class      = shift;
	my $value      = shift;
	my $lifetime   = shift;

	my $self = bless [ undef, $lifetime, time ], $class;

	$self->STORE( $value );

	return $self;
	}

sub FETCH { time - $_[0]->[2] > $_[0]->[1] ? () : $_[0]->[0] }

sub STORE { @{ $_[0] }[0,2] = ( $_[1], time ) }

1;
