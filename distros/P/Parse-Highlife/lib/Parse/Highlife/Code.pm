package Parse::Highlife::Code;

use strict;
use Parse::Highlife::Utils qw(params);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, @args ) = @_;
	$self->{'source'} = ''; # the source code that is generated
	return $self;
}

sub append
{
	my( $self, $string ) = @_;
	$self->{'source'} .= $string;
	return $self;
}

1;
